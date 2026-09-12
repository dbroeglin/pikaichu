require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require "active_support"
require "active_support/test_case"
require_relative "../../script/ci/workspace"

class LocalCITest < Minitest::Test
  class Connection
    attr_reader :commands

    def initialize
      @commands = []
    end

    def exec(command)
      commands << command
    end

    def finish
    end
  end

  def setup
    @root = Dir.mktmpdir("local-ci-test")
    @environment = {}
    @connection = Connection.new
    @workspace = LocalCI::Workspace.new(
      root: @root, environment: @environment, connect: -> { @connection }
    )
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_uses_a_unique_database_and_test_environment
    other = LocalCI::Workspace.new(root: @root, environment: {})

    @workspace.with_environment do
      assert_equal "test", @environment["RAILS_ENV"]
      assert_match %r{\Apostgresql:///pikaichu_ci_[0-9a-f]{16}\z}, @environment["DATABASE_URL"]
      assert_equal @workspace.directory.to_s, @environment["CI_RUN_DIRECTORY"]
      assert_equal "1", @environment["PARALLEL_WORKERS"]
      refute_equal @workspace.database_name, other.database_name
    end

    assert_empty @environment
  end

  def test_rejects_inherited_database_urls_before_creating_resources
    @environment["DATABASE_URL"] = "postgresql:///pikaichu_development"

    error = assert_raises(LocalCI::Error) { @workspace.with_environment { flunk } }

    assert_includes error.message, "DATABASE_URL"
    assert_empty @connection.commands
    refute @workspace.directory.exist?
  end

  def test_rejects_the_primary_database_url_before_creating_resources
    @environment["PRIMARY_DATABASE_URL"] = "postgresql:///shared_test_data"

    error = assert_raises(LocalCI::Error) { @workspace.with_environment { flunk } }

    assert_includes error.message, "PRIMARY_DATABASE_URL"
    assert_empty @connection.commands
    refute @workspace.directory.exist?
    assert_equal "postgresql:///shared_test_data", @environment["PRIMARY_DATABASE_URL"]
  end

  def test_clears_an_empty_primary_database_url_for_rails_and_restores_it
    @environment["PRIMARY_DATABASE_URL"] = ""

    @workspace.with_environment { assert_nil @environment["PRIMARY_DATABASE_URL"] }

    assert_equal "", @environment["PRIMARY_DATABASE_URL"]
  end

  def test_overrides_inherited_parallel_workers_for_rails_and_restores_the_value
    previous_executor = Minitest.parallel_executor
    @environment["PARALLEL_WORKERS"] = "4"

    @workspace.with_environment do
      ENV.stub(:[], ->(key) { @environment[key] }) do
        ActiveSupport::TestCase.parallelize(workers: 1)
      end
      assert_equal 1, Minitest.parallel_executor.size
    end

    assert_equal "4", @environment["PARALLEL_WORKERS"]
  ensure
    Minitest.parallel_executor = previous_executor
  end

  def test_rejects_an_explicit_non_test_environment
    @environment["RAILS_ENV"] = "production"

    assert_raises(LocalCI::Error) { @workspace.with_environment { flunk } }
    assert_equal "production", @environment["RAILS_ENV"]
  end

  def test_drops_only_the_database_it_created_even_when_checks_fail
    assert_raises(RuntimeError) do
      @workspace.with_environment do
        @workspace.create_database
        raise "check failed"
      end
    end

    assert_equal [
      %(CREATE DATABASE "#{@workspace.database_name}"),
      %(DROP DATABASE "#{@workspace.database_name}")
    ], @connection.commands
    assert_empty @environment
  end

  def test_does_not_drop_a_database_when_creation_failed
    @connection.stub(:exec, ->(_command) { raise PG::DuplicateDatabase, "already exists" }) do
      assert_raises(PG::DuplicateDatabase) do
        @workspace.with_environment { @workspace.create_database }
      end
    end

    assert_empty @connection.commands
  end

  def test_cleanup_failure_is_not_reported_as_success
    @workspace.with_environment do
      @workspace.create_database
      @connection.define_singleton_method(:exec) { |_command| raise PG::Error, "drop failed" }
    end
    flunk "cleanup should have failed"
  rescue PG::Error => error
    assert_equal "drop failed", error.message
    assert_empty @environment
  end

  def test_restores_environment_after_interrupt
    @environment["CHROME_DEBUG"] = "true"
    @environment["PARALLEL_WORKERS"] = "2"

    assert_raises(Interrupt) do
      @workspace.with_environment do
        assert_nil @environment["CHROME_DEBUG"]
        assert_equal "1", @environment["PARALLEL_WORKERS"]
        raise Interrupt
      end
    end

    assert_equal({ "CHROME_DEBUG" => "true", "PARALLEL_WORKERS" => "2" }, @environment)
  end

  def test_cleans_up_database_created_by_the_preparation_process
    @workspace.with_environment do
      preparation = LocalCI::Workspace.current(
        root: @root, environment: @environment, connect: -> { @connection }
      )
      preparation.create_database
    end

    assert_equal [
      %(CREATE DATABASE "#{@workspace.database_name}"),
      %(DROP DATABASE "#{@workspace.database_name}")
    ], @connection.commands
  end

  def test_preparation_rejects_a_database_url_that_does_not_match_the_run
    @workspace.with_environment do
      @environment["DATABASE_URL"] = "postgresql:///pikaichu_development"

      assert_raises(LocalCI::Error) do
        LocalCI::Workspace.current(root: @root, environment: @environment)
      end
    end

    assert_empty @connection.commands
  end

  def test_preparation_rejects_a_primary_database_url_introduced_after_setup
    @workspace.with_environment do
      @environment["PRIMARY_DATABASE_URL"] = "postgresql:///shared_test_data"

      assert_raises(LocalCI::Error) do
        LocalCI::Workspace.current(root: @root, environment: @environment)
      end
    end

    assert_empty @connection.commands
  end

  def test_preparation_requires_a_run_directory
    assert_raises(LocalCI::Error) do
      LocalCI::Workspace.current(root: @root, environment: {})
    end
  end

  def test_does_not_reuse_a_run_directory_or_its_ownership_marker
    FileUtils.mkdir_p(@workspace.directory)
    @workspace.directory.join("database-created").write("")

    assert_raises(Errno::EEXIST) { @workspace.with_environment { flunk } }
    assert_empty @connection.commands
  end

  def test_preparation_cleans_up_when_it_cannot_record_ownership
    @workspace.with_environment do
      @workspace.directory.join("database-created").mkdir

      assert_raises(Errno::EISDIR) { @workspace.create_database }
    end

    assert_equal [
      %(CREATE DATABASE "#{@workspace.database_name}"),
      %(DROP DATABASE "#{@workspace.database_name}")
    ], @connection.commands
  end
end
