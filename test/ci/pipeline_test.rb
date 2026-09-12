require "minitest/autorun"
require "minitest/mock"
require "active_support/continuous_integration"

CI = ActiveSupport::ContinuousIntegration unless defined?(CI)

class CIPipelineTest < Minitest::Test
  class Harness
    attr_reader :commands

    def initialize(fail_prepare: false, fail_lint: false)
      @commands = []
      @results = []
      @fail_prepare = fail_prepare
      @fail_lint = fail_lint
    end

    def step(_title, *command)
      commands << command
      @results << !((@fail_prepare && command.include?("ci:prepare")) || (@fail_lint && command.include?("bin/rubocop")))
    end

    def success?
      @results.all?
    end

    def failure(*)
    end
  end

  def test_failed_database_preparation_skips_tests_and_seeds_but_not_independent_checks
    harness = run_pipeline(fail_prepare: true)
    commands = harness.commands.flatten

    assert_includes commands, "bin/rubocop"
    assert_includes commands, "bin/bundler-audit"
    assert_includes commands, "missing"
    assert_includes commands, "check-consistent-interpolations"
    refute_includes commands, "test"
    refute_includes commands, "test:system"
    refute_includes commands, "db:seed:replant"
  end

  def test_successful_preparation_enables_database_checks_and_fresh_audits
    harness = run_pipeline
    commands = harness.commands.flatten

    assert_includes commands, "test"
    assert_includes commands, "test:system"
    assert_includes commands, "db:seed:replant"
    assert_includes harness.commands, [ "bin/bundler-audit", "check", "--update" ]
    refute_includes commands, "bin/setup"
  end

  def test_uses_the_standard_rails_runner_and_preparation_task
    assert_same ActiveSupport::ContinuousIntegration, CI
    assert_includes run_pipeline.commands, [ "bin/rails", "ci:prepare" ]
  end

  def test_an_independent_lint_failure_does_not_skip_database_checks
    commands = run_pipeline(fail_lint: true).commands.flatten

    assert_includes commands, "test"
    assert_includes commands, "test:system"
    assert_includes commands, "db:seed:replant"
  end

  def test_precompiles_assets_in_production_with_a_dummy_secret
    assert_includes run_pipeline.commands, [
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1" }, "bin/rails", "ci:assets"
    ]
  end

  def test_checks_missing_translations_and_interpolations_without_mutating_locales
    commands = run_pipeline.commands

    assert_includes commands, [ "bundle", "exec", "i18n-tasks", "missing" ]
    assert_includes commands, [ "bundle", "exec", "i18n-tasks", "check-consistent-interpolations" ]
    refute_includes commands.flatten, "normalize"
    refute_includes commands.flatten, "unused"
  end

  private

  def run_pipeline(fail_prepare: false, fail_lint: false)
    harness = Harness.new(fail_prepare: fail_prepare, fail_lint: fail_lint)

    CI.stub(:run, ->(&block) { harness.instance_eval(&block) }) do
      load File.expand_path("../../config/ci.rb", __dir__)
    end

    harness
  end
end
