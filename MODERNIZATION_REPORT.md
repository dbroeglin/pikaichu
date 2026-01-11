# PiKaichu Rails 8.1 Modernization Report

## Executive Summary

This document tracks the modernization of PiKaichu from Rails 7.x to Rails 8.1, following the plan outlined in MODERNIZATION.md. The modernization is being executed in phases to minimize risk and ensure the application remains stable throughout the process.

**Status:** Phase 2 (Authentication Migration) - COMPLETED  
**Started:** 2025-01-10  
**Branch:** `modernization/phase-2-authentication`

---

## Completed Work

### Phase 0: Pre-Modernization Fixes (2025-01-10)

#### 1. Fixed Taikai State Machine Reload Bug

**Issue:** System test `test_taikai_state_navigation_uses_POST_buttons` was failing because the Taikai model's state_machine method was memoizing the state machine instance, preventing `taikai.reload` from seeing updated states.

**Fix:** Removed memoization from `app/models/taikai.rb`:

```ruby
# Before (BROKEN):
def state_machine
  @state_machine ||= TaikaiStateMachine.new(self, transition_class: TaikaiTransition)
end

# After (FIXED):
def state_machine
  TaikaiStateMachine.new(self, transition_class: TaikaiTransition)
end
```

**Impact:** All 122 system tests now pass (1 intentional skip remains).

**Commit:** `c8e6cf3` - Fix taikai state reload and update deps

---

#### 2. Security Vulnerability Fixes

**Issues:**

- `action_text-trix` 2.1.15 had XSS vulnerability (GHSA-g9jg-w8vm-g96v)
- `brakeman` version check was failing

**Fixes:**

- Pinned `action_text-trix` to `~> 2.1.16` in Gemfile
- Updated `brakeman` to 7.1.2

**Verification:**

```bash
$ bundle audit check
No vulnerabilities found
```

**Commit:** `c8e6cf3` - Fix taikai state reload and update deps

---

### Phase 1: Infrastructure Modernization (2025-01-10)

#### 3. Installed Solid Gems (Cache, Queue, Cable)

**Goal:** Replace in-memory cache/queue with durable, production-ready Solid infrastructure.

**Actions:**

1. Added gems to Gemfile:

   - `gem "solid_cache"`
   - `gem "solid_queue"`
   - `gem "solid_cable"`

2. Ran installers:

   ```bash
   bin/rails solid_cache:install
   bin/rails solid_queue:install
   bin/rails solid_cable:install
   ```

3. Generated configurations:

   - `config/cache.yml` - 256MB max size, environment-specific namespaces
   - `config/queue.yml` - 1 dispatcher, 3 threads, configurable processes
   - `config/recurring.yml` - Hourly cleanup job for old Solid Queue entries
   - `config/cable.yml` - Production uses solid_cable adapter with 0.1s polling

4. Generated database schemas:

   - `db/cache_schema.rb` - `solid_cache_entries` table
   - `db/queue_schema.rb` - 10 tables for job queue management
   - `db/cable_schema.rb` - `solid_cable_messages` table

5. Updated production environment (`config/environments/production.rb`):
   ```ruby
   config.cache_store = :solid_cache_store
   config.active_job.queue_adapter = :solid_queue
   config.solid_queue.connects_to = { database: { writing: :queue } }
   ```

**Development/Test Environments:**

- Development continues to use `:memory_store` (simpler for local dev)
- Test uses `:null_store` (faster for test runs)
- Solid gems are production-focused and don't require changes to dev/test

**Commit:** `b8ca467` - Pin minitest to 5.x for Rails 8.1 compatibility

---

#### 4. Fixed Minitest 6.0 Incompatibility

**Issue:** After installing Solid gems, test suite showed "0 runs, 0 assertions" instead of running tests. Investigation revealed Rails 8.1.1 is incompatible with Minitest 6.0.1 API changes.

**Error:**

```ruby
wrong number of arguments (given 3, expected 1..2) (ArgumentError)
  rails/test_unit/line_filtering.rb:7:in 'run'
```

**Root Cause:** Minitest 6.0 changed the `run` method signature, but Rails 8.1.1's test helpers haven't been updated yet.

**Fix:** Pinned minitest to 5.x in Gemfile:

```ruby
group :development, :test do
  # Pin minitest to 5.x until Rails 8.1 supports Minitest 6.0 API changes
  gem "minitest", "~> 5.20"
end
```

**Verification:**

```bash
$ bin/rails test
182 runs, 695 assertions, 0 failures, 0 errors, 0 skips

$ bin/rails test:system
122 runs, 1039 assertions, 0 failures, 0 errors, 1 skips
```

**Note for Future:** When Rails adds Minitest 6.0 support, remove the version pin to use the latest minitest.

**Commit:** `b8ca467` - Pin minitest to 5.x for Rails 8.1 compatibility

---

#### 5. Removed Obsolete Rails 7.1 Framework Defaults

**File Removed:** `config/initializers/new_framework_defaults_7_1.rb`

**Rationale:** This 280-line file was created during the Rails 7.0 → 7.1 upgrade to gradually enable new defaults. Since PiKaichu is now on Rails 8.1 with `config.load_defaults 8.1`, all these defaults are already applied. The file contained only commented-out code and was no longer needed.

**Verification:** Ran test suite after removal to confirm no regressions.

**Commit:** `1dca41a` - Remove obsolete Rails 7.1 framework defaults file

---

#### 6. Added Kamal and Thruster (Deployment Tools)

**Goal:** Add modern deployment tools for production environments.

**Kamal:**

- Docker-based deployment tool from Basecamp
- Enables deployment to any server with Docker
- Generated `config/deploy.yml` configuration file
- Created `.kamal/` directory with deployment hooks
- Does NOT require changes to existing infrastructure (optional tool)

**Thruster:**

- HTTP asset caching and compression for Puma
- X-Sendfile acceleration
- Automatic gzip compression
- Will improve production performance when enabled

**Installation:**

```bash
bundle add kamal --require false
bundle add thruster --require false
kamal init
```

**Note:** These are optional deployment tools. The application works without them, but they improve deployment and production performance when used.

**Commit:** `1fc7b85` - Add Kamal, Thruster and update to rubocop-rails-omakase

---

#### 7. Updated RuboCop to rubocop-rails-omakase

**Goal:** Adopt Rails official style guide and simplify RuboCop configuration.

**Before:**

- 3 separate gems: `rubocop`, `rubocop-rails`, `rubocop-capybara`
- `.rubocop.yml` with 357 lines of configuration
- Many cops manually enabled/disabled
- 99 offenses before auto-correct

**After:**

- Single gem: `rubocop-rails-omakase`
- `.rubocop.yml` with 26 lines (94% reduction)
- Inherits from omakase defaults
- 0 offenses (all auto-corrected)

**Auto-corrections Applied:**

- 652 string literal quotes (single → double)
- 328 array bracket spacing
- 37 trailing commas in arrays
- 34 trailing whitespace
- 27 trailing commas in hashes
- 20 trailing empty lines
- 9 hash syntax modernizations
- And more...

**Total:** 971 offenses automatically corrected across 98 files.

**Benefits:**

- Consistent code style aligned with Rails conventions
- Less configuration to maintain
- Automatic updates when omakase updates
- Cleaner, more readable code

**Verification:**

```bash
$ bin/rubocop
210 files inspected, no offenses detected
```

**Commit:** `1fc7b85` - Add Kamal, Thruster and update to rubocop-rails-omakase

---

## Test Status

### Current Test Results (2025-01-10)

**Unit Tests:**

- 182 runs
- 695 assertions
- 0 failures
- 0 errors
- 0 skips

**System Tests:**

- 122 runs
- 1039 assertions
- 0 failures
- 0 errors
- 1 skip (intentional)

**Total:** 304 test runs, 1734 assertions, ALL PASSING ✅

---

## Pending Work

### ✅ Phase 1: COMPLETED

All Phase 1 tasks have been completed:

- ✅ Solid Cache, Queue, and Cable installed
- ✅ Obsolete initializers removed
- ✅ Kamal and Thruster deployment tools added
- ✅ RuboCop updated to rubocop-rails-omakase

**Status:** Merged to main (2025-01-10)

---

### ✅ Phase 2: COMPLETED

All Phase 2 tasks have been completed:

- ✅ Completely removed Devise gem
- ✅ Created Rails 8 native authentication system
- ✅ Updated all controllers to use Authentication concern
- ✅ Created Session model with bcrypt password hashing
- ✅ Implemented password reset functionality
- ✅ Created authentication views (login, password reset)
- ✅ Updated test helpers for integration and controller tests
- ✅ Fixed all test failures (193 runs, 721 assertions, 0 failures, 0 errors)

**Status:** Ready to merge to main

**Commit Summary:**

- `cdd77a8` - Complete Devise removal and Rails 8 authentication migration
- `ddd4f90` - Fix authentication test helpers for controller and integration tests
- `5bc292e` - Fix all remaining test failures after Devise removal

**Key Changes:**

1. **Removed Devise completely:**

   - Deleted gem from Gemfile
   - Deleted config/initializers/devise.rb
   - Deleted app/views/devise/ directory
   - Deleted config/locales/devise/ translations
   - Removed devise routes and modules from User model

2. **Implemented Rails 8 Authentication:**

   - Created app/models/session.rb with user_id, ip_address, user_agent
   - Created app/controllers/concerns/authentication.rb with session management
   - Created app/controllers/sessions_controller.rb (login/logout)
   - Created app/controllers/passwords_controller.rb (password reset)
   - Updated User model to use has_secure_password only
   - Created bilingual authentication views (EN/FR)

3. **Fixed Test Infrastructure:**
   - Updated SignInHelper to properly handle integration vs controller tests
   - Created ControllerAuthenticationStub for controller test authentication
   - Updated Rails8AuthTestHelper with session creation
   - Fixed 54 failures + 30 errors → all tests passing

**Test Results After Phase 2:**

- 193 runs
- 721 assertions
- 0 failures ✅
- 0 errors ✅
- 0 skips

---

1. Replace `jsbundling-rails` (esbuild) with `importmap-rails`
2. Replace `cssbundling-rails` (Sass) with Rails 8 asset pipeline
3. Migrate Bulma CSS imports to new system
4. Update Stimulus controllers for new pipeline
5. Migrate custom JavaScript (SortableJS, autocomplete)
6. Remove `package.json` and Node.js dependency

**Challenge:** Bulma is distributed as Sass files, may need to compile externally or find alternative approach.

---

## Important Notes and Decisions

### 1. Multi-Database Configuration

The Solid gems (Cache, Queue, Cable) use separate database connections. The installers created separate schema files:

- `db/cache_schema.rb`
- `db/queue_schema.rb`
- `db/cable_schema.rb`

**Production configuration:**

```ruby
# config/environments/production.rb
config.solid_queue.connects_to = { database: { writing: :queue } }
```

**Current database.yml does NOT have multi-database configuration** - this is intentional. The Solid gems use the default database connection by default, and the multi-database setup is only for production deployments that want separate databases for performance/isolation.

**Action for deployment:** If you want separate databases in production, update `database.yml` to include queue, cache, and cable database configurations.

### 2. Minitest Version Pin

The `minitest ~> 5.20` pin is temporary and should be removed once Rails releases a fix for Minitest 6.0 compatibility. Track this issue:

- Rails issue: (check https://github.com/rails/rails/issues)
- Monitor Rails 8.1.x releases for "minitest 6" mentions

### 3. Test Parallelization

Currently using `parallelize(workers: 1)` in test_helper.rb. This is intentional to avoid database conflicts during modernization. Consider increasing workers after authentication migration is complete.

### 4. Solid Queue Recurring Jobs

The installer created `config/recurring.yml` with a cleanup job:

```yaml
clear_finished_jobs_hourly:
  class: SolidQueue::ClearFinishedJobsJob
  schedule: every hour
```

This will automatically remove completed jobs from the database every hour. Adjust the schedule if you need longer retention for debugging.

### 5. Asset Pipeline Deprecation Warnings

The following Sass deprecation warning appears during builds:

```
Deprecation Warning [import]: Sass @import rules are deprecated and will be removed in Dart Sass 3.0.0.
app/assets/stylesheets/application.bulma.scss 68:9  root stylesheet
```

This is NOT urgent but should be addressed before migrating to importmap. The warning is about `@import 'custom.bulma'` which should be changed to `@use` or `@forward`.

---

## Risks and Mitigation

### High Risk Items

1. **Authentication Migration (Phase 2)**

   - **Risk:** Breaking login/logout, losing user sessions, password reset failures
   - **Mitigation:** Run Devise and Rails 8 auth in parallel, extensive testing, gradual rollout
   - **Rollback:** Keep Devise gem until 100% verified working

2. **Asset Pipeline Migration (Phase 3)**
   - **Risk:** JavaScript/CSS not loading, Stimulus controllers breaking
   - **Mitigation:** Test in development thoroughly, check browser console for errors
   - **Rollback:** Keep jsbundling-rails and cssbundling-rails until verified

### Medium Risk Items

1. **Solid Queue in Production**

   - **Risk:** Background jobs failing, recurring jobs not running
   - **Mitigation:** Monitor logs, test all background jobs manually
   - **Rollback:** Change back to async adapter if needed

2. **Solid Cache in Production**
   - **Risk:** Cache misses, performance degradation
   - **Mitigation:** Monitor response times, check cache hit rates
   - **Rollback:** Change back to memory_store (but will lose cache on restart)

### Low Risk Items (Completed)

✅ Solid gems installation - transparent to existing code  
✅ Minitest version pin - only affects test execution  
✅ Removing obsolete initializers - code already uses new defaults

---

## Next Steps

1. **Decide on optional Phase 1 items:**

   - Do we need Kamal/Thruster? (deployment tools)
   - Do we want rubocop-rails-omakase? (will require code style changes)

2. **Begin Phase 2 Authentication Migration:**

   - Install Rails 8 authentication generator
   - Run generator with `--api false` (we need HTML views)
   - Review generated code before committing
   - Create detailed migration plan for User model

3. **Create backup before Phase 2:**
   - Tag current commit as `pre-phase-2-backup`
   - Document rollback procedure
   - Consider deploying Phase 1 changes to production first

---

## Testing Strategy

### Before Each Phase

1. Run full test suite: `bin/rails test && bin/rails test:system`
2. Check for deprecation warnings
3. Run security audit: `bundle audit check`
4. Run Brakeman: `bin/brakeman`
5. Verify RuboCop: `bin/rubocop`

### After Each Major Change

1. Commit atomically with descriptive messages
2. Run tests again
3. Manually test critical paths in browser
4. Document any issues or workarounds

### Before Deployment

1. Run full test suite in CI (if available)
2. Test in staging environment
3. Perform manual smoke tests
4. Monitor logs during deployment

---

## Useful Commands

### Running Tests

```bash
# Unit tests only
bin/rails test

# System tests only
bin/rails test:system

# Specific test file
bin/rails test test/models/taikai_test.rb

# With verbose output
bin/rails test --verbose
```

### Security Checks

```bash
# Check for vulnerable gems
bundle audit check

# Run Brakeman security scanner
bin/brakeman

# Update Brakeman database
bundle update brakeman
```

### Database Management

```bash
# Dump main schema
bin/rails db:schema:dump

# Prepare test database
RAILS_ENV=test bin/rails db:prepare

# Check Solid Queue jobs (in Rails console)
bin/rails runner "puts SolidQueue::Job.count"
```

### Git Commands

```bash
# View current branch
git branch --show-current

# Show uncommitted changes
git status

# Create new branch for Phase 2
git checkout -b modernization/phase-2-authentication

# Tag current commit
git tag pre-phase-2-backup
```

---

## References

- [MODERNIZATION.md](MODERNIZATION.md) - Original modernization plan
- [Rails 8.0 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [Solid Queue Documentation](https://github.com/rails/solid_queue)
- [Solid Cache Documentation](https://github.com/rails/solid_cache)
- [Solid Cable Documentation](https://github.com/rails/solid_cable)
- [Rails Authentication Generator](https://github.com/rails/rails/pull/50446)

---

## Changelog

| Date       | Phase         | Author         | Description                                        |
| ---------- | ------------- | -------------- | -------------------------------------------------- |
| 2025-01-10 | Pre-Phase     | GitHub Copilot | Fixed taikai state reload bug                      |
| 2025-01-10 | Pre-Phase     | GitHub Copilot | Updated action_text-trix and brakeman for security |
| 2025-01-10 | Phase 1       | GitHub Copilot | Installed Solid Cache, Queue, and Cable            |
| 2025-01-10 | Phase 1       | GitHub Copilot | Fixed Minitest 6.0 incompatibility                 |
| 2025-01-10 | Phase 1       | GitHub Copilot | Removed obsolete Rails 7.1 defaults file           |
| 2025-01-10 | Phase 1       | GitHub Copilot | Added Kamal and Thruster deployment tools          |
| 2025-01-10 | Phase 1       | GitHub Copilot | Updated RuboCop to rubocop-rails-omakase           |
| 2025-01-10 | Phase 1       | GitHub Copilot | **Phase 1 COMPLETED** - All tasks done             |
| 2025-01-10 | Documentation | GitHub Copilot | Created MODERNIZATION_REPORT.md                    |
| 2025-01-10 | Documentation | GitHub Copilot | Updated report with Phase 1 completion             |
| 2025-01-11 | Phase 2       | GitHub Copilot | Created Rails 8 authentication infrastructure      |
| 2025-01-11 | Phase 2       | GitHub Copilot | Completely removed Devise gem and all files        |
| 2025-01-11 | Phase 2       | GitHub Copilot | Fixed authentication test helpers                  |
| 2025-01-11 | Phase 2       | GitHub Copilot | Fixed all test failures (193 tests, 0 failures)    |
| 2025-01-11 | Phase 2       | GitHub Copilot | **Phase 2 COMPLETED** - Ready for merge            |

---

**Last Updated:** 2025-01-11 (Phase 2 Complete)  
**Report Version:** 2.0  
**Contact:** See git log for authors
