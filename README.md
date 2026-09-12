# PiKaichu - Kyudo Tournament Management System

A comprehensive Ruby on Rails 8.1 application for managing Kyudo (Japanese archery) tournaments with support for multiple tournament formats, complex scoring systems, and role-based access control.

## Tech Stack

**Core:**
- **Ruby:** 3.4.7
- **Rails:** 8.1.3.1 (fully modernized to Rails 8 patterns)
- **Database:** PostgreSQL with custom enums
- **Authentication:** Rails 8 built-in authentication (has_secure_password + Sessions)
- **Authorization:** Pundit (role-based)

**Frontend:**
- **JavaScript:** Importmap-rails (no Node.js bundler needed)
- **CSS:** Sass/Bulma via cssbundling-rails
- **Interactivity:** Hotwire (Turbo + Stimulus)

**Background Jobs & Infrastructure:**
- **Queue:** Solid Queue (database-backed Active Job)
- **Cache:** Solid Cache (database-backed Rails.cache)
- **WebSockets:** Solid Cable (database-backed Action Cable)

**Key Gems:**
- **State Machine:** Statesman (tournament workflow)
- **Auditing:** audited (change tracking)
- **I18n:** Mobility (model translations EN/FR)
- **Testing:** Minitest with Apparition (headless Chrome)

## Prerequisites

- Ruby 3.4.7
- PostgreSQL 14+
- Yarn (for CSS bundling only)

## Setup

### 1. Install Dependencies

```bash
bundle install
yarn install
```

### 2. Database Setup

```bash
# Create and migrate database
bin/rails db:create
bin/rails db:migrate

# Load default data (staff roles, etc.)
bin/rails db:seed
```

### 3. Start Development Server

```bash
# Start all services (Rails server + CSS watcher)
bin/dev
```

The application will be available at http://localhost:3000

## Running Tests

```bash
# Unit and integration tests
RAILS_ENV=test bin/rails db:prepare db:fixtures:load
bin/rails test

# System tests (headless Chrome)
RAILS_ENV=test bin/rails db:fixtures:load
bin/rails test:system

# Watch mode (auto-run tests on file changes)
guard
```

Use a dedicated test database; set `DATABASE_URL` when running in an isolated worktree.
Fixture loading replaces database contents. Preload fixtures before each suite because
some tests discover tournament cases from database records when their files are loaded.
System tests use Selenium with headless Chrome, which must be installed.

CI runs both suites, RuboCop, Bundler Audit, and Brakeman. Test failures and lint/security
findings block their respective jobs; coverage reporting is not configured.

## Development

### Asset Pipeline

- **JavaScript:** Uses importmap-rails. No esbuild/webpack needed. Modules are loaded directly from CDN or vendored.
- **CSS:** Uses cssbundling-rails with Sass. Bulma framework with custom styling.

### Authentication

Modern Rails 8 authentication:
- Session-based with secure signed cookies
- Password reset via signed tokens (no database tokens)
- Rate limiting on login and password reset
- Email confirmation required

### Background Jobs

Production uses the primary PostgreSQL database for Solid Queue, Solid Cache, and
Solid Cable, matching the Azure deployment's single `DATABASE_URL`. Their tables
are installed by the normal application migrations:

```bash
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/jobs
```

The Docker entrypoint prepares the database before starting the web server.
Run `bin/jobs` as a separate worker, or set `SOLID_QUEUE_IN_PUMA=true` to use the
existing Puma worker integration, which the Azure template enables. No separate
cache, queue, or cable databases are required; these services share the primary
Active Record connection pool.
The Solid migration only adds tables; it does not modify tournament data. Retain
these tables when rolling back an application image so queued work is not lost.

Solid Queue handles background jobs:
```ruby
# Queue a job
MyJob.perform_later(arg1, arg2)

# View queue dashboard
# Visit /solid_queue in development
```

### Code Quality

```bash
# Linting
bin/rubocop
bin/rubocop -a  # Auto-fix

# Security audit
bundle audit check
bin/brakeman
```

## Deployment

Application is containerized with Docker:

```bash
# Build image
docker build -t pikaichu .

# Run container
docker run -p 3000:3000 pikaichu
```

**Azure Deployment:**
- Bicep templates in `infra/` directory
- Azure Container Apps with PostgreSQL Flexible Server
- See `azure.yaml` for Azure Developer CLI config

```bash
# Deploy to Azure
azd up
```

## Key Features

### Tournament Formats

- **Individual:** Solo archer competition
- **Team:** 3-5 archers per team
- **2in1:** Hybrid format with both individual and team rankings
- **Matches:** Elimination bracket (4 or 8 teams)

### Scoring Types

- **Kinteki:** Traditional hit/miss scoring
- **Enteki:** Distance-based scoring (0, 3, 5, 7, 9, 10 points)

### Tournament States

Statesman-based workflow:
1. **new** - Tournament structure can be modified
2. **registration** - Adding participants, teams, dojos
3. **marking** - Score entry and validation
4. **tie_break** - Resolving ties
5. **done** - Tournament complete (immutable)

### Staff Roles

- **taikai_admin** - Full tournament control
- **dojo_admin** - Manage own dojo's participants
- **chairman** - Tournament director
- **marking_referee** - Score entry
- **shajo_referee** - Floor referee
- **target_referee** - Target judge
- More roles documented in [docs/STAFF_ROLES.md](docs/STAFF_ROLES.md)

## Documentation

- **[Useful Notes](docs/NOTES.md)** - Development recipes and console commands
- **[Staff Roles](docs/STAFF_ROLES.md)** - Role definitions and constraints
- **[Modernization Report](MODERNIZATION_REPORT.md)** - Rails 8 upgrade documentation
- **[Copilot Instructions](.github/copilot-instructions.md)** - Comprehensive technical guide

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `bin/rails test` and `bin/rails test:system`
4. Run linters: `bin/rubocop`
5. Submit a pull request

## License

See LICENSE file for details.

## Rails 8 Modernization

This application was fully modernized to Rails 8 in January 2025:
- ✅ Removed Devise, implemented Rails 8 authentication
- ✅ Migrated to importmap-rails (from jsbundling-rails)
- ✅ Added Solid Queue, Solid Cache, Solid Cable
- ✅ Updated to Rails 8 code patterns and best practices
- ✅ Full test coverage maintained throughout migration

See [MODERNIZATION_REPORT.md](MODERNIZATION_REPORT.md) for detailed migration notes.