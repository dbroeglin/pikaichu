# Run using bin/ci

CI.run do
  step "Setup: Disposable test database", "bin/rails", "ci:prepare"
  database_ready = success?

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit", "check", "--update"
  step "Security: Importmap vulnerability audit", "bin/ci-importmap"
  step "Security: Brakeman code analysis", "bin/brakeman", "--quiet", "--no-pager", "--exit-on-warn", "--exit-on-error"

  step "Translations: Missing keys", "bundle", "exec", "i18n-tasks", "missing"
  step "Translations: Interpolation consistency", "bundle", "exec", "i18n-tasks", "check-consistent-interpolations"

  step "Build: Production assets", { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1" }, "bin/rails", "ci:assets"

  if database_ready
    step "Tests: Rails", "bin/rails", "test"
    step "Tests: System", "bin/rails", "test:system"
    step "Tests: Seeds", "bin/rails", "db:seed:replant"
  else
    failure "Skipping database-dependent tests and seeds because database preparation failed."
  end
end
