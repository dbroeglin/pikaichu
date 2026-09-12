require "fileutils"
require "pathname"
require "pg"
require "securerandom"

module LocalCI
  class Error < StandardError; end

  class Workspace
    ROOT = File.expand_path("../..", __dir__)

    attr_reader :database_name, :directory

    def self.open(&block)
      new.with_environment(&block)
    end

    def self.current(root: ROOT, environment: ENV, **options)
      path = environment["CI_RUN_DIRECTORY"]
      raise Error, "Database preparation must run inside bin/ci." unless path

      workspace = new(root: root, environment: environment, database_name: File.basename(path), **options)
      unless environment["RAILS_ENV"] == "test" &&
          environment["DATABASE_URL"] == workspace.database_url &&
          environment["PRIMARY_DATABASE_URL"].nil? &&
          path == workspace.directory.to_s && workspace.directory.directory?
        raise Error, "Database preparation does not match the isolated CI run."
      end

      workspace
    end

    def initialize(root: ROOT, environment: ENV, connect: -> { PG.connect(dbname: "postgres") },
      database_name: "pikaichu_ci_#{SecureRandom.hex(8)}")
      unless /\Apikaichu_ci_[0-9a-f]{16}\z/.match?(database_name)
        raise Error, "Invalid disposable CI database name."
      end

      @root = Pathname.new(root)
      @environment = environment
      @connect = connect
      @database_name = database_name
      @directory = @root.join("tmp/ci", database_name)
      @database_created = false
      @directory_created = false
    end

    def database_url
      "postgresql:///#{database_name}"
    end

    def with_environment
      validate_environment!
      values = {
        "RAILS_ENV" => "test",
        "DATABASE_URL" => database_url,
        "PRIMARY_DATABASE_URL" => nil,
        "PARALLEL_WORKERS" => "1",
        "CI_RUN_DIRECTORY" => directory.to_s,
        "CHROME_DEBUG" => nil
      }
      previous = values.to_h { |key, _| [ key, @environment[key] ] }

      begin
        FileUtils.mkdir_p(directory.parent)
        directory.mkdir
        @directory_created = true
        values.each { |key, value| set_environment(key, value) }
        puts "CI database: #{database_name}"
        puts "CI artifacts: #{directory}"
        yield self
      ensure
        begin
          drop_database if @database_created || (@directory_created && ownership_file.file?)
        ensure
          @directory_created = false
          previous.each { |key, value| set_environment(key, value) }
        end
      end
    end

    def create_database
      with_connection { |connection| connection.exec("CREATE DATABASE #{quoted_database_name}") }
      @database_created = true
      begin
        ownership_file.write("")
      rescue SystemCallError
        drop_database
        raise
      end
      true
    end

    private

    def validate_environment!
      %w[DATABASE_URL PRIMARY_DATABASE_URL].each do |variable|
        unless @environment[variable].to_s.empty?
          raise Error, "Unset #{variable} before running local CI; use PGHOST, PGPORT, PGUSER and PGPASSWORD for its disposable database."
        end
      end

      unless [ nil, "", "test" ].include?(@environment["RAILS_ENV"])
        raise Error, "Local CI requires RAILS_ENV=test or an unset RAILS_ENV."
      end
    end

    def drop_database
      with_connection { |connection| connection.exec("DROP DATABASE #{quoted_database_name}") }
      @database_created = false
      ownership_file.delete if ownership_file.file?
    end

    def ownership_file
      directory.join("database-created")
    end

    def quoted_database_name
      PG::Connection.quote_ident(database_name)
    end

    def with_connection
      connection = @connect.call
      yield connection
    ensure
      connection&.finish
    end

    def set_environment(key, value)
      value.nil? ? @environment.delete(key) : @environment[key] = value
    end
  end
end
