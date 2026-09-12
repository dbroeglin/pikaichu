require "minitest/autorun"
require "minitest/mock"
require "rake"
require "rails"
require "active_record"
require "active_record/database_configurations"
require "tmpdir"
require "fileutils"
require "json"
require_relative "../../script/ci/workspace"

class CITasksTest < Minitest::Test
  DATABASE_NAME = "pikaichu_ci_0123456789abcdef"

  def setup
    @previous_rake = Rake.application
    Rake.application = Rake::Application.new
    @directory = Pathname.new(Dir.mktmpdir("ci-tasks-test"))
    @previous_directory = ENV["CI_RUN_DIRECTORY"]
    ENV["CI_RUN_DIRECTORY"] = @directory.to_s
    load File.expand_path("../../lib/tasks/ci.rake", __dir__)
  end

  def teardown
    Rake.application = @previous_rake
    ENV["CI_RUN_DIRECTORY"] = @previous_directory
    FileUtils.remove_entry(@directory)
  end

  def test_creates_database_before_invoking_rails_preparation
    calls = []
    workspace = Object.new
    workspace.define_singleton_method(:database_name) { DATABASE_NAME }
    workspace.define_singleton_method(:create_database) { calls << :create }
    Rake::Task.define_task("db:prepare") { calls << :prepare }

    with_database_configuration(test_database_configuration) do
      LocalCI::Workspace.stub(:current, workspace) { Rake::Task["ci:prepare"].invoke }
    end

    assert_equal [ :create, :prepare ], calls
  end

  def test_does_not_prepare_an_existing_database_when_creation_fails
    workspace = Object.new
    workspace.define_singleton_method(:database_name) { DATABASE_NAME }
    workspace.define_singleton_method(:create_database) { raise PG::DuplicateDatabase, "already exists" }
    Rake::Task.define_task("db:prepare") { flunk "must not prepare an existing database" }

    with_database_configuration(test_database_configuration) do
      LocalCI::Workspace.stub(:current, workspace) do
        assert_raises(PG::DuplicateDatabase) { Rake::Task["ci:prepare"].invoke }
      end
    end
  end

  def test_rejects_rails_primary_url_precedence_before_creating_or_preparing_a_database
    configuration = test_database_configuration
    with_database_configuration(configuration, primary_url: "postgresql:///shared_test_data") do
      resolved = ActiveRecord::DatabaseConfigurations.new(configuration).configs_for(env_name: "test", name: "primary")
      assert_equal "shared_test_data", resolved.database

      assert_unsafe_database_configuration_rejected
    end
  end

  def test_rejects_a_database_url_embedded_in_the_rails_configuration
    configuration = { "test" => { "url" => "postgresql:///shared_test_data" } }

    with_database_configuration(configuration) { assert_unsafe_database_configuration_rejected }
  end

  def test_rejects_additional_test_databases_outside_the_single_database_run
    configuration = {
      "test" => {
        "primary" => { "adapter" => "postgresql", "database" => DATABASE_NAME },
        "queue" => { "adapter" => "postgresql", "database" => "shared_queue_data" }
      }
    }

    with_database_configuration(configuration) { assert_unsafe_database_configuration_rejected }
  end

  def test_asset_task_configures_isolated_output_before_precompiling
    with_assets do |assets|
      Rake::Task.define_task("assets:precompile") do
        assert_equal @directory.join("assets"), assets.output_path
        assert_equal @directory.join("assets/.manifest.json"), assets.manifest_path
        FileUtils.mkdir_p(assets.output_path)
        assets.manifest_path.write(JSON.generate("application.js" => { "digested_path" => "application-123.js" }))
      end

      capture_io { Rake::Task["ci:assets"].invoke }
    end
  end

  def test_asset_task_rejects_empty_or_invalid_manifest_shapes
    [ {}, [] ].each do |manifest|
      with_assets do |assets|
        Rake::Task.define_task("assets:precompile") do
          FileUtils.mkdir_p(assets.output_path)
          assets.manifest_path.write(JSON.generate(manifest))
        end

        capture_io do
          assert_raises(RuntimeError) { Rake::Task["ci:assets"].invoke }
        end
      end
      Rake::Task["assets:precompile"].clear
      Rake::Task["ci:assets"].reenable
    end
  end

  def test_asset_task_rejects_non_production_execution
    Rails.stub(:env, ActiveSupport::StringInquirer.new("test")) do
      assert_raises(RuntimeError) { Rake::Task["ci:assets"].invoke }
    end
  end

  private

  def test_database_configuration
    { "test" => { "adapter" => "postgresql", "database" => "pikaichu_test" } }
  end

  def with_database_configuration(configuration, primary_url: nil)
    previous = ENV.values_at("DATABASE_URL", "PRIMARY_DATABASE_URL")
    ENV["DATABASE_URL"] = "postgresql:///#{DATABASE_NAME}"
    ENV["PRIMARY_DATABASE_URL"] = primary_url
    application = Struct.new(:config).new(Struct.new(:database_configuration).new(configuration))
    Rails.stub(:application, application) do
      Rails.stub(:env, ActiveSupport::StringInquirer.new("test")) { yield }
    end
  ensure
    ENV["DATABASE_URL"], ENV["PRIMARY_DATABASE_URL"] = previous
  end

  def assert_unsafe_database_configuration_rejected
    workspace = Object.new
    workspace.define_singleton_method(:database_name) { DATABASE_NAME }
    workspace.define_singleton_method(:create_database) { raise "must not create a database before checking the resolved target" }
    Rake::Task.define_task("db:prepare") { flunk "must not prepare an unowned database" }

    LocalCI::Workspace.stub(:current, workspace) do
      assert_raises(LocalCI::Error) { Rake::Task["ci:prepare"].invoke }
    end
  end

  def with_assets
    assets = Struct.new(:output_path, :manifest_path).new
    application = Struct.new(:config).new(Struct.new(:assets).new(assets))
    Rails.stub(:application, application) do
      Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) { yield assets }
    end
  end
end
