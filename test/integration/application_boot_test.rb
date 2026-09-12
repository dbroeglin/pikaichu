require "test_helper"
require "open3"
require "uri"

class ApplicationBootTest < ActiveSupport::TestCase
  test "all application code can be eager loaded" do
    assert_nothing_raised do
      Rails.application.eager_load!
    end
  end

  test "production boots with Solid services on the primary database" do
    database = ActiveRecord::Base.connection_db_config.configuration_hash
    options = database.slice(:host, :port, :username, :password, :sslmode)
    database_url = "postgresql:///#{URI::DEFAULT_PARSER.escape(database.fetch(:database))}?#{URI.encode_www_form(options)}"

    script = <<~RUBY
      require "./config/environment"

      raise "Not running in production" unless Rails.env.production?
      primary_database = ActiveRecord::Base.connection_db_config.database
      [SolidCache::Entry, SolidQueue::Job, SolidCable::Message].each do |model|
        raise "\#{model} is not using the primary database" unless model.connection_db_config.database == primary_database
        raise "\#{model.table_name} is missing" unless model.table_exists?
      end
    RUBY

    stdout, stderr, status = Open3.capture3(
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1", "DATABASE_URL" => database_url },
      RbConfig.ruby, "-e", script, chdir: Rails.root
    )

    assert status.success?, "#{stdout}\n#{stderr}"
  end
end
