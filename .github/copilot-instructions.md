# Pikaichu - Kyudo Tournament Management System - Detailed Instructions

## Project Overview

Pikaichu is a comprehensive Ruby on Rails 7.2 application for managing Kyudo (Japanese archery) tournaments. It supports multiple tournament formats, complex scoring systems, role-based access control, and full bilingual support (EN/FR).

**Tech Stack:**
- **Backend:** Ruby 3.3.5, Rails 7.2.2, PostgreSQL with custom enums
- **Frontend:** Hotwire (Turbo + Stimulus), Bulma CSS framework, esbuild for JS bundling
- **Authentication:** Devise
- **Authorization:** Pundit (role-based)
- **State Management:** Statesman gem for tournament workflow
- **I18n:** Mobility gem for model translations
- **Testing:** Minitest with Apparition (headless Chrome), Factory Bot, Fixture Builder
- **Deployment:** Docker containerized, Azure Container Apps with Bicep templates

---

## Core Domain Concepts

### Taikai (Tournament)
The central entity with a strict state machine workflow controlling all operations.

**States (immutable progression):**
1. **new** - Initial state; tournament structure can be modified
2. **registration** - Adding participants, teams, and dojos
3. **marking** - Score entry and validation
4. **tie_break** - Resolving ties after all scores finalized
5. **done** - Tournament complete; no further modifications allowed

**Tournament Forms (enum):**
- `individual` - Individual archer competition
- `team` - Team-based competition (3-5 archers per team)
- `2in1` - Hybrid format: both individual and team rankings
- `matches` - Bracket-style elimination (4 or 8 teams)

**Scoring Types (enum):**
- `kinteki` - Hit/miss scoring (traditional target)
- `enteki` - Distance-based scoring with values [0, 3, 5, 7, 9, 10]

**Key Attributes:**
- `total_num_arrows`: Must be 8, 12, or 20 (kinteki), or 4 (matches)
- `num_arrows`: Always 4 (arrows per round)
- `num_rounds`: Calculated as `total_num_arrows / 4`
- `tachi_size`: 3 or 5 (archers shooting together)
- `num_targets`: 3, 5, 6, 9, or 10
- `distributed`: Boolean - if false, only one participating dojo allowed

### Participants
Individual archers with optional link to `Kyudojin` (archer registry).

**Relationships:**
- Belongs to `ParticipatingDojo` (required)
- Belongs to `Team` (optional, for team formats)
- Belongs to `Kyudojin` (optional)

**Scoring:**
- Has many `Score` records (one per match or tournament)
- Each score has multiple `Result` records (one per arrow)

### Teams
Groups of 3-5 participants from the same participating dojo.

**Special Properties:**
- Team scores aggregate participant scores
- `mixed` flag indicates mixed-gender teams
- `shortname` used for bracket displays

### Results and Scores

**Result Model:**
- Tracks individual arrow outcomes
- Fields: `round`, `index`, `status` (hit/miss/unknown), `value` (Enteki only)
- `final` flag: Once true, result is immutable (except via `overriden` flag)
- State validation: Cannot update finalized results unless marked as overridden

**Score Model:**
- Aggregates results for a participant or team
- Two sets of values:
  - `hits`/`value` - Finalized results only
  - `intermediate_hits`/`intermediate_value` - Includes non-finalized
- Automatic recalculation on result changes
- Team scores automatically recalculate from participant scores

**Scoring Flow:**
1. Archer shoots 4 arrows (one round)
2. Results marked hit/miss (or value for Enteki)
3. Round finalized → results locked, scores recalculated
4. Process repeats for remaining rounds

### Staff Roles

Defined in `db/seeds.rb` and `docs/STAFF_ROLES.md`:

| Code                  | Purpose                              | Key Permissions                    |
| --------------------- | ------------------------------------ | ---------------------------------- |
| `taikai_admin`        | Full tournament control              | All operations                     |
| `dojo_admin`          | Manage own dojo's participants       | Marking, participant management    |
| `chairman`            | Tournament director                  | Required for marking state         |
| `marking_referee`     | Score entry                          | Mark scores                        |
| `shajo_referee`       | Floor referee                        | Required for marking state         |
| `yatori`              | Target caller                        | Observational                      |
| `target_referee`      | Target judge                         | Required for marking state         |
| `operations_chairman` | Logistics coordinator                | Setup and coordination             |

**State Transition Requirements:**
- `registration → marking`: Requires chairman, shajo_referee, target_referee roles assigned
- `marking → tie_break`: All participating dojos must have finalized results

---

## Architecture Patterns

### State Machine (Statesman)

**Critical Implementation Details:**

```ruby
# Always set current_user before transitions for audit trail
taikai.current_user = current_user
taikai.transition_to!(:marking)
```

**State Transition Guards:**
- Validate required staff roles present
- Check all dojos have drawn tachis (shooting order)
- Verify all results finalized before tie-break

**Transition Callbacks:**
- `before_transition`: Creates audit event via `TaikaiEvent.state_transition`
- `registration → marking`: Calls `create_tachi_and_scores` (generates empty score/result records)
- `marking → registration`: Calls `delete_tachis_and_scores` (cleanup for rollback)
- `marking → tie_break`: Computes intermediate ranks via `Leaderboard`

### State-Based Validation (Concern)

**ValidateChangeBasedOnState:**
- Prevents changes to models when taikai is in `done` state
- Restricts structural changes in `marking`/`tie_break` states
- Exception: `rank` field updates allowed for tie-break resolution

**Usage Pattern:**
```ruby
# Include in models that need state protection
include ValidateChangeBasedOnState

# Requires model to define `taikai` method
def taikai
  participating_dojo.taikai # or similar navigation
end
```

### Authorization (Pundit)

**Policy Structure:**
```ruby
# app/policies/taikai_policy.rb
ADMIN_ROLES = [:taikai_admin]
MARKING_ROLES = ADMIN_ROLES + [:marking_referee, :target_referee, :dojo_admin]

def marking_update?
  taikai.in_state?(:marking) && (user.admin? || taikai.roles?(user, MARKING_ROLES))
end
```

**Always Check Authorization:**
```ruby
@taikai = authorize(Taikai.find(params[:id]), :marking_show?)
```

### Internationalization

**Mobility Gem Configuration:**
- Model translations for `name`, `label`, `description` fields
- Stored as JSONB columns: `name_en`, `name_fr`, etc.
- Locale switching via URL params or user preferences

**Staff Roles Example:**
```ruby
StaffRole.create!(
  code: :chairman,
  label_fr: 'Directeur du tournoi',
  label_en: 'Chairman'
)
```

**Access Pattern:**
```ruby
I18n.locale = :fr
staff_role.label # Returns 'Directeur du tournoi'
```

### Scoring Architecture

**Result → Score → Participant/Team Hierarchy:**

```ruby
# Adding a result
participant.add_result(match_id, 'hit', nil) # Kinteki
participant.add_result(match_id, 'hit', 7)   # Enteki

# Finalizing a round
participant.finalize_round(round_number, match_id)

# Cascade: Result save → Score.recalculate_individual_score → Team.recalculate_team_score
```

**Key Validations:**
- Previous rounds must be finalized before marking next round
- Enteki results require value [0, 3, 5, 7, 9, 10]
- Finalized results immutable (raises `cannot_update_if_finalized`)

---

## Development Workflows

### Local Development Setup

```bash
# Install dependencies
bundle install
yarn install

# Database setup
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Creates default staff roles

# Start development server (Procfile.dev)
bin/dev
# Runs: Rails server (port 3000), JS build watcher, CSS build watcher
```

### Guard Workflow

```bash
# Auto-restart server and run tests on file changes
guard

# Watches: app/, lib/, config/, test/
# Runs relevant tests based on changed files
```

### Testing Strategy

**Test Organization:**
- `test/models/` - Model unit tests
- `test/controllers/` - Controller tests
- `test/integration/` - Integration tests
- `test/system/` - System tests (Apparition/Capybara)
- `test/factories/` - Factory Bot definitions
- `test/fixtures/` - Fixture Builder generated data

**Running Tests:**
```bash
# All tests
bin/rails test

# Specific test file
bin/rails test test/models/taikai_test.rb

# System tests (headless Chrome)
bin/rails test:system

# Rebuild fixtures for complex scenarios
rake spec:fixture_builder:rebuild
RAILS_ENV=test rake db:fixtures:load
```

### Asset Pipeline

**JavaScript (esbuild):**
```bash
# Build once
yarn build

# Watch mode (included in bin/dev)
yarn build --watch

# Entry point: app/javascript/application.js
# Output: app/assets/builds/application.js
```

**CSS (Sass + Bulma):**
```bash
# Build once
yarn build:css

# Watch mode (included in bin/dev)
yarn build:css --watch

# Entry point: app/assets/stylesheets/application.bulma.scss
# Output: app/assets/builds/application.css
```

**Stimulus Controllers:**
- Located in `app/javascript/controllers/`
- Auto-registered via `application.js`
- Example: `marking_controller.js` for live score entry

---

## Database Conventions

### PostgreSQL Enums

**Defined via `activerecord-postgres_enum` gem:**
```ruby
# In migrations
create_enum :taikai_form, ['individual', 'team', '2in1', 'matches']

# In models
enum :form, {
  individual: 'individual',
  team: 'team',
  '2in1': '2in1',
  matches: 'matches'
}, prefix: :form

# Usage
taikai.form_individual? # => true/false
taikai.form # => 'individual'
```

**Critical:** Enum migrations require special handling:
```ruby
# Adding enum values
add_enum_value :taikai_form, 'new_value', before: 'existing_value'

# Cannot remove enum values without recreating enum
```

### Auditing (audited gem)

**Automatic Tracking:**
```ruby
class Taikai < ApplicationRecord
  audited # Tracks all changes
end

# View history
taikai.audits
taikai.audited_changes
```

### Translations (mobility)

**JSONB Column Pattern:**
```ruby
# Migration
add_column :staff_roles, :label, :jsonb

# Model
translates :label, type: :string

# Access
I18n.locale = :en
staff_role.label # Uses locale-specific value
staff_role.label_en # Direct access
```

---

## Critical File Locations

### Core Models
- `app/models/taikai.rb` - Main tournament model with form/scoring logic
- `app/models/taikai_state_machine.rb` - State transitions and guards
- `app/models/participant.rb` - Archer with scoring methods
- `app/models/result.rb` - Individual arrow result
- `app/models/score.rb` - Aggregated scoring with ScoreValue class
- `app/models/staff_role.rb` - Role definitions
- `app/models/team.rb` - Team scoring and composition

### Concerns
- `app/models/concerns/scoreable.rb` - Score association mixin
- `app/models/concerns/validate_change_based_on_state.rb` - State protection

### Controllers
- `app/controllers/taikais_controller.rb` - CRUD and tournament generation
- `app/controllers/marking_controller.rb` - Live score entry interface
- `app/controllers/leaderboard_controller.rb` - Rankings display
- `app/controllers/tie_break_controller.rb` - Tie resolution
- `app/controllers/rectification_controller.rb` - Score corrections

### Policies
- `app/policies/taikai_policy.rb` - Tournament authorization rules
- `app/policies/participating_dojo_policy.rb` - Dojo access control

### Services
- `app/services/test_data_service.rb` - Test data generation helpers

### Views
- `app/views/taikais/` - Tournament management UI
- `app/views/marking/` - Score entry interface
- `app/views/leaderboard/` - Rankings displays

### Configuration
- `config/routes.rb` - Complex nested routes by tournament state
- `config/locales/` - EN/FR translations
- `config/initializers/` - Gem configurations
- `db/seeds.rb` - Default staff roles

### Documentation
- `docs/NOTES.md` - Development recipes and data manipulation
- `docs/STAFF_ROLES.md` - Role definitions and constraints

### Infrastructure
- `Dockerfile` - Multi-stage build with Node.js for assets
- `infra/` - Azure Bicep templates for Container Apps deployment
- `azure.yaml` - Azure Developer CLI configuration
- `.devcontainer/` - VS Code dev container setup

---

## Common Development Tasks

### Creating a Tournament

```ruby
taikai = Taikai.new(
  shortname: 'test-2024',
  name: 'Test Tournament',
  form: 'individual',
  scoring: 'kinteki',
  total_num_arrows: 12,
  num_targets: 6,
  tachi_size: 3,
  start_date: Date.today,
  end_date: Date.today + 1,
  current_user: user  # CRITICAL: Required for audit trail
)
taikai.save!
# Creates taikai_admin staff automatically
```

### State Transitions

```ruby
taikai = Taikai.find(id)
taikai.current_user = current_user  # CRITICAL: Always set

# Check if transition possible
taikai.can_transition_to?(:marking) # => true/false

# Perform transition (raises if guard fails)
taikai.transition_to!(:marking)
# Creates tachis and empty score/result records

# Rollback
taikai.transition_to!(:registration)
# Deletes tachis and scores
```

### Adding Participants

```ruby
participating_dojo = taikai.participating_dojos.create!(
  display_name: 'Kyudo Club',
  dojo: Dojo.find_or_create_by(name: 'Club Name')
)

participant = participating_dojo.participants.create!(
  firstname: 'John',
  lastname: 'Doe',
  kyudojin: Kyudojin.find_by(email: 'john@example.com') # Optional
)
```

### Marking Scores (Kinteki)

```ruby
participant = Participant.find(id)

# Add results one by one
participant.add_result(nil, 'hit', nil)   # Arrow 1: hit
participant.add_result(nil, 'miss', nil)  # Arrow 2: miss
participant.add_result(nil, 'hit', nil)   # Arrow 3: hit
participant.add_result(nil, 'hit', nil)   # Arrow 4: hit

# Finalize round (locks results, recalculates scores)
participant.finalize_round(1, nil)
```

### Marking Scores (Enteki)

```ruby
participant = Participant.find(id)

# Value automatically sets status (0 = miss, >0 = hit)
participant.add_result(nil, 'hit', 7)    # 7 points
participant.add_result(nil, 'hit', 5)    # 5 points
participant.add_result(nil, 'miss', 0)   # 0 points
participant.add_result(nil, 'hit', 9)    # 9 points

participant.finalize_round(1, nil)
# Score: hits=3, value=21
```

### Generating Test Results

```ruby
# From docs/NOTES.md

# Random results for all participants
Taikai.find_by(shortname: 'test-tournament')
  .participants.map(&:results).flatten
  .each { |r|
    r.status = ['hit', 'miss'].sample
    r.final = true
    r.save!
  }

# Reset all results
Taikai.find_by(shortname: 'test-tournament')
  .participants.map(&:results).flatten
  .each { |r|
    r.status = nil
    r.final = false
    r.save(validate: false)
  }

# Enteki random results
Taikai.find_by(shortname: 'enteki-tournament')
  .participants.map(&:results).flatten
  .each { |r|
    r.value = [0, 3, 5, 7, 9, 10].sample
    r.status = r.value == 0 ? 'miss' : 'hit'
    r.final = true
    r.save!
  }
```

### Creating Matches Tournament from 2in1

```ruby
# After 2in1 tournament finalized
new_taikai = Taikai.create_from_2in1(
  taikai_id,
  current_user,
  'semifinals',      # shortname suffix
  'Semi-Finals',     # name suffix
  4                  # bracket size: 4 or 8 teams
)

# Automatically:
# - Selects top N non-mixed teams
# - Creates new taikai with matches form
# - Copies participants and staff
# - Generates bracket structure
```

### Leaderboard Computation

```ruby
leaderboard = Leaderboard.new(taikai_id: taikai.id, validated: true)

# Individual rankings
participants_by_score, scores_by_dojo = leaderboard.compute_individual_leaderboard

# Team rankings
teams_by_score, scores_by_dojo = leaderboard.compute_team_leaderboard

# Matches bracket
teams_by_score, matches = leaderboard.compute_matches_leaderboard
```

---

## Common Pitfalls and Solutions

### 1. Missing current_user on State Transitions

**Problem:** Audit trail breaks, no event records created

**Solution:**
```ruby
# ✅ Correct
taikai.current_user = current_user
taikai.transition_to!(:marking)

# ❌ Wrong - No audit trail
taikai.transition_to!(:marking)
```

### 2. Modifying Finalized Results

**Problem:** Validation error when trying to update locked results

**Solution:**
```ruby
# For legitimate corrections, use overridden flag
result = Result.find(id)
result.overriden = true
result.status = 'hit'
result.save! # Now allowed despite final=true
```

### 3. Guard Failures on State Transitions

**Problem:** Transition fails with guard error

**Checklist:**
- Staff roles assigned? (chairman, shajo_referee, target_referee for marking)
- Tachis drawn for all participating dojos?
- All results finalized for tie-break transition?

```ruby
# Debug guard conditions
taikai.staffs.map { |s| s.role&.code }
taikai.participating_dojos.all?(&:drawn?)
taikai.participating_dojos.all?(&:finalized?)
```

### 4. PostgreSQL Enum Migrations

**Problem:** Cannot alter enum values easily

**Solution:**
```ruby
# Adding value (safe)
add_enum_value :taikai_form, 'new_form', before: 'matches'

# Removing value (requires recreation)
# 1. Create new enum
# 2. Migrate data
# 3. Drop old enum
# 4. Rename new enum
# See activerecord-postgres_enum docs
```

### 5. Asset Compilation in Production

**Problem:** Assets not found in Docker build

**Cause:** Node.js required for esbuild, Yarn for dependencies

**Solution:** Dockerfile includes Node.js installation:
```dockerfile
# Already handled in Dockerfile
RUN curl -fSL ${NODE_DL_URL} -o /tmp/nodejs.tar.xz
RUN npm install --global yarn
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
```

### 6. Score Recalculation Cascades

**Problem:** Performance issues with large tournaments

**Observation:**
- `Result.save` → `Score.recalculate_individual_score`
- → `Team.recalculate_team_score` (if team exists)
- Uses `results.reload` (N+1 risk)

**Mitigation:**
```ruby
# Batch finalize to reduce recalculations
results.update_all(final: true)
score.recalculate_individual_score # Single call
```

### 7. Timezone Issues

**Prevention:** Always use `Date.today` or `DateTime.now`, not `Time.now`

```ruby
# ✅ Correct - Respects Rails timezone config
Date.today
DateTime.now

# ❌ Avoid - System timezone
Time.now
```

---

## Azure Deployment

### Architecture
- **Service:** Azure Container Apps
- **Database:** Azure Database for PostgreSQL Flexible Server
- **Build:** Docker multi-stage with Node.js for assets
- **IaC:** Bicep templates in `infra/` directory

### Deployment Commands

```bash
# Azure Developer CLI workflow
azd auth login
azd up  # Provision + deploy

# Get environment variables
azd env get-values > .env

# Manual deployment
azd deploy

# View logs
azd monitor
```

### Environment Variables

Required in production:
- `DATABASE_URL` - PostgreSQL connection string
- `RAILS_MASTER_KEY` - For credentials decryption
- `SECRET_KEY_BASE` - Session encryption
- `RAILS_ENV=production`

### Database Migrations

```bash
# Run migrations on deployed instance
azd exec -- bin/rails db:migrate

# Or via Docker container
docker exec <container> bin/rails db:migrate
```

### Asset Precompilation

Handled automatically in Dockerfile:
```dockerfile
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
```

**Note:** Uses dummy secret to avoid requiring real credentials at build time.

---

## Testing Conventions

### Factory Bot

**Location:** `test/factories/`

**Usage:**
```ruby
# test/models/taikai_test.rb
test "should create taikai" do
  user = create(:user)
  taikai = create(:taikai, current_user: user)
  assert taikai.persisted?
end
```

### Fixture Builder

**Purpose:** Generate complex, realistic tournament scenarios

**Rebuild Fixtures:**
```bash
rake spec:fixture_builder:rebuild
RAILS_ENV=test rake db:fixtures:load
```

### System Tests

**Headless Chrome via Apparition:**
```ruby
# test/system/marking_test.rb
test "marking workflow" do
  login_as @user
  visit show_marking_path(@taikai)
  
  # Turbo interactions
  click_button "Hit"
  assert_text "Score updated"
end
```

**Running:**
```bash
bin/rails test:system
# Captures screenshots on failure in tmp/screenshots/
```

---

## Code Style and Conventions

### Rubocop Configuration

**File:** `.rubocop.yml`

**Enforcement:**
```bash
rubocop
rubocop -a  # Auto-fix
```

### Rails Conventions

- **Fat models, thin controllers:** Business logic in models/services
- **Concerns for shared behavior:** `Scoreable`, `ValidateChangeBasedOnState`
- **Service objects:** Complex operations (e.g., `TestDataService`)
- **Pundit policies:** All authorization logic

### Naming Conventions

- **Models:** Singular, `Participant`, `Taikai`
- **Tables:** Plural, `participants`, `taikais`
- **Enums:** String-backed with human-readable values
- **State machine states:** Symbol format `:new`, `:marking`

### Testing Conventions

- **One test file per model/controller**
- **Descriptive test names:** `test "should prevent changes when taikai is done"`
- **Factory usage over fixtures** (except complex scenarios)

**Important**: When asked to fix a bug, always write or update tests to cover the issue first.

---

## Performance Considerations

### Database Queries

**N+1 Prevention:**
```ruby
# ✅ Eager loading
@taikais = Taikai.includes(:participants, :teams, :matches)

# ❌ Lazy loading
@taikais = Taikai.all
@taikais.each { |t| t.participants } # N+1
```

### Score Recalculation

**Avoid in loops:**
```ruby
# ❌ Slow - recalculates on each save
results.each { |r| r.update!(status: 'hit') }

# ✅ Fast - batch update + single recalc
results.update_all(status: 'hit')
score.recalculate_individual_score
```

### Turbo Frames

**Used extensively for live updates:**
- Marking interface updates without full page reload
- Leaderboard real-time refresh
- Participant list updates

---

## Security Considerations

### Pundit Authorization

**Always authorize before actions:**
```ruby
# Controllers
before_action do
  @taikai = authorize(Taikai.find(params[:id]))
end

# Views
<% if policy(@taikai).update? %>
  <%= link_to "Edit", edit_taikai_path(@taikai) %>
<% end %>
```

### State Protection

**Models enforce state-based immutability:**
- Cannot modify done taikais
- Cannot modify participants during marking
- Cannot update finalized results

### Devise Security

- Password encryption via bcrypt
- Session timeout configured
- Remember me functionality

### Audit Trail

- All changes logged via `audited` gem
- State transitions recorded via `TaikaiEvent`
- User attribution via `current_user`

---

## Useful Rails Console Commands

```ruby
# Find taikai
t = Taikai.find_by(shortname: 'test-2024')

# Check state
t.current_state                    # => "new"
t.in_state?(:new)                  # => true
t.can_transition_to?(:registration) # => true

# Get staff roles
t.staffs.with_role(:chairman)

# Scores by participant
t.participants.first.scores.first.to_ascii

# Generate ASCII representation
puts t.to_ascii

# Leaderboard
l = Leaderboard.new(taikai_id: t.id, validated: true)
participants, scores = l.compute_individual_leaderboard

# Reset passwords (development)
User.all.each { |u| u.update(password: 'password') }
```

---

## Key Takeaways for AI Assistants

1. **Always set `current_user` before state transitions** - Critical for audit trail
2. **Respect state machine guards** - Understand why transitions fail
3. **Results are immutable when finalized** - Use `overriden` flag for corrections
4. **Score recalculation is automatic** - Triggered by result saves
5. **Authorization is mandatory** - Use Pundit policies in all controllers
6. **PostgreSQL enums need special handling** - Cannot easily modify values
7. **Test fixtures are generated** - Use Fixture Builder for complex scenarios
8. **Asset pipeline requires Node.js** - Included in Docker build
9. **Turbo frames for interactivity** - No full page reloads in marking
10. **Bilingual by design** - All user-facing text must support EN/FR

---

## Additional Resources

- **Statesman Gem:** https://github.com/gocardless/statesman
- **Pundit Gem:** https://github.com/varvet/pundit
- **Mobility Gem:** https://github.com/shioyama/mobility
- **Apparition Gem:** https://github.com/twalpole/apparition
- **Rails 7.2 Docs:** https://guides.rubyonrails.org/
- **Bulma CSS:** https://bulma.io/documentation/
- **Stimulus JS:** https://stimulus.hotwired.dev/
- **Turbo:** https://turbo.hotwired.dev/

---

## Version History

- **Initial creation:** 2025-11-14 - Comprehensive analysis of Pikaichu repository