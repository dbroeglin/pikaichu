namespace :ci do
  desc "Create and prepare the disposable database allocated by bin/ci"
  task :prepare do
    require_relative "../../script/ci/workspace"
    require "active_record/database_configurations"

    workspace = LocalCI::Workspace.current
    configurations = ActiveRecord::DatabaseConfigurations.new(Rails.application.config.database_configuration)
    databases = configurations.configs_for(env_name: "test", include_hidden: true)
    unless databases.one? && databases.first.name == "primary" &&
        databases.first.adapter == "postgresql" && databases.first.database == workspace.database_name
      raise LocalCI::Error, "Rails must resolve exactly one test database matching the disposable CI database."
    end

    workspace.create_database
    Rake::Task["db:prepare"].invoke
  end

  desc "Smoke-test production asset precompilation in the CI run directory"
  task :assets do
    require "json"

    raise "The asset smoke check requires RAILS_ENV=production." unless Rails.env.production?

    directory = Pathname.new(ENV.fetch("CI_RUN_DIRECTORY")).join("assets")
    Rails.application.config.assets.output_path = directory
    Rails.application.config.assets.manifest_path = directory.join(".manifest.json")
    Rake::Task["assets:precompile"].invoke

    manifest = JSON.parse(directory.join(".manifest.json").read)
    unless manifest.is_a?(Hash) && manifest.any?
      raise "Asset precompilation did not produce a nonempty manifest."
    end

    puts "Compiled #{manifest.length} production assets into #{directory}."
  end
end
