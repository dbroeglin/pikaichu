# PiKaichu Rails 8.x Modernization Plan

This document outlines a comprehensive plan to modernize the PiKaichu application to idiomatic Rails 8.x, using the `tries/2026-01-07-dbroeglin-azure-rails-demo` as a reference for modern Rails patterns.

## Executive Summary

PiKaichu is currently a Rails 8.1 application but still uses patterns from earlier Rails versions, most notably Devise for authentication. The goal is to modernize to idiomatic Rails 8.x while maintaining full functionality.

**Key Changes:**
- Replace Devise with Rails 8's built-in authentication
- Adopt Solid Queue, Solid Cache, and Solid Cable (the "Solid Trifecta")
- Migrate from jsbundling-rails/cssbundling-rails to importmap-rails (optional)
- Clean up legacy configuration files
- Modernize test helpers

---

## Pre-Modernization Checklist

### 1. Establish Baseline Test Coverage

Before making any changes, ensure all existing tests pass and document the current state.

```bash
# Run full test suite and capture baseline
bin/rails test
bin/rails test:system

# Run security audits
bin/brakeman
bin/bundler-audit

# Run linting
bin/rubocop
```

**Deliverable:** All tests must pass. Document any existing failures that are unrelated to modernization.

### 2. Create a Backup/Branch Strategy

```bash
git checkout -b modernization/phase-1-preparation
```

---

## Phase 1: Infrastructure Modernization (Low Risk)

### 1.1 Add Solid Queue, Solid Cache, and Solid Cable

**Current State:** Using in-memory cache/queue adapters
**Target State:** Using database-backed Solid gems

#### Steps:

1. Add gems to `Gemfile`:
```ruby
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

2. Run installers:
```bash
bundle install
bin/rails solid_cache:install
bin/rails solid_queue:install
bin/rails solid_cable:install
```

3. Add configuration files (reference from demo app):
   - `config/cache.yml`
   - `config/queue.yml`
   - `config/recurring.yml`

4. Update `config/environments/production.rb`:
```ruby
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

5. Run migrations for Solid gems.

**Tests:** Run full test suite after installation.

---

### 1.2 Add Kamal and Thruster (Optional - Deployment)

```ruby
# Deploy this application anywhere as a Docker container
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma
gem "thruster", require: false
```

Add deployment configuration:
- `config/deploy.yml`
- `bin/kamal`
- `bin/thrust`
- `bin/jobs`

**Tests:** Verify Docker build still works.

---

### 1.3 Clean Up Legacy Configuration

#### Remove `config/initializers/new_framework_defaults_7_1.rb`

Since `config.load_defaults 8.1` is already set in `config/application.rb`, this file is obsolete.

**Steps:**
1. Review all commented configurations in the file
2. Ensure any needed settings are properly configured in `config/application.rb`
3. Delete the file

**Tests:** Run full test suite.

---

### 1.4 Update RuboCop Configuration

**Current:** Using individual rubocop gems
**Target:** Using rubocop-rails-omakase (Rails official style guide)

```ruby
# Replace
gem 'rubocop', require: false
gem 'rubocop-capybara', require: false
gem 'rubocop-rails', require: false

# With
gem "rubocop-rails-omakase", require: false
```

Update `.rubocop.yml` to inherit from omakase or keep current configuration if preferred.

**Tests:** Run `bin/rubocop` and fix any new offenses.

---

## Phase 2: Authentication Migration (High Risk - Most Critical)

This is the most significant change. Replace Devise with Rails 8's built-in authentication.

### 2.1 Current Devise Features in Use

Based on analysis of `app/models/user.rb` and `config/initializers/devise.rb`:

| Devise Module | Currently Used | Rails 8 Equivalent |
|--------------|----------------|-------------------|
| `database_authenticatable` | ✅ | `has_secure_password` |
| `registerable` | ✅ | Custom controller |
| `recoverable` | ✅ | `PasswordsController` + `PasswordsMailer` |
| `rememberable` | ✅ | Session-based with permanent cookie |
| `validatable` | ✅ | Custom validations |
| `confirmable` | ✅ | Custom implementation needed |
| `lockable` | ✅ | Custom implementation needed |

### 2.2 Database Schema Changes

**Current User Table Columns (Devise):**
- `email` → rename to `email_address`
- `encrypted_password` → rename to `password_digest`
- `reset_password_token`, `reset_password_sent_at` → remove (handled by signed tokens)
- `remember_created_at` → remove (sessions table handles this)
- `confirmation_token`, `confirmed_at`, `confirmation_sent_at`, `unconfirmed_email` → **Keep or migrate**
- `unlock_token`, `locked_at`, `failed_attempts` → **Keep or migrate**
- `firstname`, `lastname`, `locale`, `admin` → **Keep**

**New Sessions Table:**
```ruby
create_table "sessions" do |t|
  t.datetime "created_at", null: false
  t.string "ip_address"
  t.datetime "updated_at", null: false
  t.string "user_agent"
  t.bigint "user_id", null: false
  t.index ["user_id"], name: "index_sessions_on_user_id"
end
```

### 2.3 Migration Strategy

#### Step 1: Create Parallel Authentication System

1. Generate Rails 8 authentication scaffold (for reference):
```bash
bin/rails generate authentication
```

2. Create new migration to add Sessions table and modify Users table:
```ruby
class ModernizeAuthentication < ActiveRecord::Migration[8.1]
  def change
    # Create sessions table
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    # Add new columns to users
    add_column :users, :email_address, :string
    add_column :users, :password_digest, :string

    # Copy data
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET email_address = email;
          UPDATE users SET password_digest = encrypted_password;
        SQL
      end
    end
  end
end
```

#### Step 2: Create Authentication Concern

Create `app/controllers/concerns/authentication.rb`:
```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |s|
        Current.session = s
        cookies.signed.permanent[:session_id] = { value: s.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def current_user
      Current.session&.user
    end
end
```

#### Step 3: Create Current Model

Create `app/models/current.rb`:
```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

#### Step 4: Create Session Model

Create `app/models/session.rb`:
```ruby
class Session < ApplicationRecord
  belongs_to :user
end
```

#### Step 5: Update User Model

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Keep audited
  audited

  # Add normalizes (Rails 8 feature)
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :firstname, :lastname, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, presence: true

  self.non_audited_columns = [:password_digest]

  scope :confirmed, -> { where.not("confirmed_at IS NULL") }
  scope :containing, ->(query) { confirmed.where <<~SQL, "%#{query}%", "%#{query}%", "%#{query}%" }
    email_address ILIKE ? OR firstname ILIKE ? OR lastname ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end

  # For compatibility during transition
  def email
    email_address
  end

  def email=(value)
    self.email_address = value
  end
end
```

#### Step 6: Create Controllers

**SessionsController:**
```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: I18n.t('sessions.invalid_credentials')
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
```

**PasswordsController:**
```ruby
class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to new_session_path, notice: I18n.t('passwords.reset_sent')
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: I18n.t('passwords.reset_success')
    else
      redirect_to edit_password_path(params[:token]), alert: I18n.t('passwords.reset_failed')
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: I18n.t('passwords.invalid_token')
    end
end
```

#### Step 7: Create PasswordsMailer

```ruby
class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @signed_id = user.signed_id(purpose: :password_reset, expires_in: 15.minutes)
    mail to: user.email_address, subject: I18n.t('passwords_mailer.reset.subject')
  end
end
```

#### Step 8: Update Routes

```ruby
Rails.application.routes.draw do
  # Remove: devise_for :users
  
  # Add:
  resource :session
  resources :passwords, param: :token
  
  # Keep all other routes...
end
```

#### Step 9: Update ApplicationController

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Remove: before_action :authenticate_user!
  # Remove: before_action :configure_permitted_parameters, if: :devise_controller?
  
  around_action :switch_locale
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Update allow_browser for modern browsers
  allow_browser versions: :modern

  protected

  def user_not_authorized(_)
    flash[:alert] = I18n.t('pundit.not_authorized', default: 'You are not authorized to perform this action.')
    redirect_to root_path, method: :get
  end

  def switch_locale(&)
    locale = params[:locale] || current_user&.locale || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
```

#### Step 10: Create Views

Create new views in `app/views/sessions/` and `app/views/passwords/`:
- `sessions/new.html.erb`
- `passwords/new.html.erb`
- `passwords/edit.html.erb`

Keep Bulma styling consistent with existing views.

#### Step 11: Update Test Helpers

Update `test/test_helper.rb`:
```ruby
module SignInHelper
  def sign_in_as(user)
    user = users(user) if user.is_a?(Symbol)
    throw "Sign-in helper needs a user" if user.nil?

    post session_path, params: { email_address: user.email_address, password: "password" }
    
    assert_response :redirect
    follow_redirect!
    assert_response :success
    
    user
  end
end

module ActionDispatch
  class IntegrationTest
    include AuthorizationHelpers
    include SignInHelper
    # Remove: include Devise::Test::IntegrationHelpers
  end
end
```

### 2.4 Email Confirmation (Confirmable) Implementation

Since email confirmation is required, we need to implement this feature:

#### Step 1: Add confirmation columns (if not already present)

The current schema already has confirmation columns from Devise:
- `confirmation_token`
- `confirmed_at`
- `confirmation_sent_at`
- `unconfirmed_email`

These can be reused with the new authentication system.

#### Step 2: Update User Model for Confirmation

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  
  # Generate confirmation tokens
  generates_token_for :confirmation, expires_in: 3.days do
    email_address
  end
  
  # Generate password reset tokens
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  audited
  
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6, maximum: 128 }, allow_nil: true
  validates :firstname, :lastname, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, presence: true

  self.non_audited_columns = [:password_digest]

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :containing, ->(query) { confirmed.where <<~SQL, "%#{query}%", "%#{query}%", "%#{query}%" }
    email_address ILIKE ? OR firstname ILIKE ? OR lastname ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def send_confirmation_instructions
    UserMailer.confirmation_instructions(self, generate_token_for(:confirmation)).deliver_later
  end

  def send_password_reset_instructions
    PasswordsMailer.reset(self).deliver_later
  end

  # Compatibility aliases during transition
  alias_method :email, :email_address
  
  def email=(value)
    self.email_address = value
  end
end
```

#### Step 3: Create ConfirmationsController

```ruby
class ConfirmationsController < ApplicationController
  allow_unauthenticated_access
  
  def new
    # Show form to request new confirmation email
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.send_confirmation_instructions unless user.confirmed?
    end
    redirect_to new_session_path, notice: I18n.t('confirmations.sent')
  end

  def show
    user = User.find_by_token_for(:confirmation, params[:token])
    
    if user
      user.confirm!
      redirect_to new_session_path, notice: I18n.t('confirmations.confirmed')
    else
      redirect_to new_confirmation_path, alert: I18n.t('confirmations.invalid_token')
    end
  end
end
```

#### Step 4: Create RegistrationsController

```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      @user.send_confirmation_instructions
      redirect_to new_session_path, notice: I18n.t('registrations.confirmation_sent')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :firstname, :lastname, :locale)
  end
end
```

#### Step 5: Update Routes for Confirmable

```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :confirmations, only: [:new, :create, :show], param: :token
  resource :registration, only: [:new, :create]
  
  # ... rest of routes
end
```

#### Step 6: Create UserMailer

```ruby
class UserMailer < ApplicationMailer
  def confirmation_instructions(user, token)
    @user = user
    @token = token
    mail to: user.email_address, subject: I18n.t('user_mailer.confirmation_instructions.subject')
  end
end
```

#### Step 7: Create Views

**`app/views/registrations/new.html.erb`:**
```erb
<div class="container">
  <div class="columns">
    <div class="column is-one-third is-offset-one-third">
      <div class="card">
        <header class="card-header">
          <p class="card-header-title"><%= t('.sign_up') %></p>
        </header>
        <div class="card-content">
          <%%= form_with model: @user, url: registration_path do |f| %>
            <div class="field">
              <%%= f.label :firstname, class: "label" %>
              <%%= f.text_field :firstname, class: "input", required: true %>
            </div>
            
            <div class="field">
              <%%= f.label :lastname, class: "label" %>
              <%%= f.text_field :lastname, class: "input", required: true %>
            </div>
            
            <div class="field">
              <%%= f.label :email_address, class: "label" %>
              <%%= f.email_field :email_address, class: "input", required: true %>
            </div>
            
            <div class="field">
              <%%= f.label :password, class: "label" %>
              <%%= f.password_field :password, class: "input", required: true %>
            </div>
            
            <div class="field">
              <%%= f.label :password_confirmation, class: "label" %>
              <%%= f.password_field :password_confirmation, class: "input", required: true %>
            </div>
            
            <div class="field">
              <%%= f.label :locale, class: "label" %>
              <%%= f.select :locale, I18n.available_locales, {}, class: "select" %>
            </div>
            
            <%%= f.submit t('.sign_up'), class: "button is-primary" %>
          <%% end %>
        </div>
        <footer class="card-content">
          <%%= link_to t('.already_have_account'), new_session_path %>
        </footer>
      </div>
    </div>
  </div>
</div>
```

**`app/views/confirmations/new.html.erb`:**
```erb
<div class="container">
  <div class="columns">
    <div class="column is-one-third is-offset-one-third">
      <div class="card">
        <header class="card-header">
          <p class="card-header-title"><%= t('.resend_confirmation') %></p>
        </header>
        <div class="card-content">
          <%%= form_with url: confirmations_path do |f| %>
            <div class="field">
              <%%= f.label :email_address, class: "label" %>
              <%%= f.email_field :email_address, class: "input", required: true %>
            </div>
            <%%= f.submit t('.send'), class: "button is-primary" %>
          <%% end %>
        </div>
      </div>
    </div>
  </div>
</div>
```

#### Step 8: Update Authentication to Check Confirmation

Update `app/controllers/sessions_controller.rb`:
```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      if user.confirmed?
        start_new_session_for user
        redirect_to after_authentication_url
      else
        redirect_to new_session_path, alert: I18n.t('sessions.unconfirmed')
      end
    else
      redirect_to new_session_path, alert: I18n.t('sessions.invalid_credentials')
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
```

### 2.5 Lockable Feature - REMOVED

Since account locking is not needed, we will:
1. Remove `lockable` from Devise configuration
2. Not implement locking in the new authentication system
3. Optionally remove these columns in a cleanup migration:
   - `unlock_token`
   - `locked_at`
   - `failed_attempts`

### 2.6 Feature Parity Considerations

#### Confirmable Feature

Email confirmation IS required. See section 2.4 for full implementation details including:
- `generates_token_for :confirmation` in User model
- `ConfirmationsController` for handling confirmation flow
- `RegistrationsController` for user self-registration
- `UserMailer` for sending confirmation emails
- Updated `SessionsController` to check confirmation status

#### Lockable Feature - NOT NEEDED

Account locking is not required. The lockable columns will be removed in Phase 4.

### 2.5 Testing the Authentication Migration

Create comprehensive tests:

```ruby
# test/controllers/sessions_controller_test.rb
class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_path
    assert_response :success
  end

  test "should create session with valid credentials" do
    user = users(:admin)
    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "should not create session with invalid credentials" do
    post session_path, params: { email_address: "wrong@email.com", password: "wrong" }
    assert_redirected_to new_session_path
  end

  test "should destroy session" do
    sign_in_as(:admin)
    delete session_path
    assert_redirected_to new_session_path
  end
end
```

---

## Phase 3: Asset Pipeline Migration to Importmap (Rails-Native)

### 3.1 Current State

- Using `jsbundling-rails` with esbuild
- Using `cssbundling-rails` with Sass
- Node.js dependencies in `package.json`:
  - `@hotwired/stimulus` ^3.2.2
  - `@hotwired/turbo-rails` ^8.0.20
  - `bulma` ^1.0.4
  - `bulma-divider` ^0.2.0
  - `bulma-timeline` ^3.0.5
  - `@fortawesome/fontawesome-free` ^7.1.0
  - `sortablejs` ^1.15.6
  - `stimulus-autocomplete` ^3.1.0
  - `esbuild`, `sass`

### 3.2 Migration Strategy

We'll migrate to importmap-rails for JavaScript while keeping cssbundling-rails for CSS (Bulma requires Sass compilation).

#### Step 1: Install importmap-rails

```bash
bundle add importmap-rails
bin/rails importmap:install
```

#### Step 2: Pin JavaScript Dependencies

```bash
# Core Hotwire
bin/importmap pin @hotwired/turbo-rails
bin/importmap pin @hotwired/stimulus

# Stimulus controllers from npm
bin/importmap pin sortablejs
bin/importmap pin stimulus-autocomplete
```

Update `config/importmap.rb`:
```ruby
# Pin npm packages from jspm.io (default CDN)
pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.12
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.12
pin "sortablejs" # @1.15.6
pin "stimulus-autocomplete" # @3.1.0

# Pin local controllers
pin_all_from "app/javascript/controllers", under: "controllers"
```

#### Step 3: Update Application JavaScript

Update `app/javascript/application.js`:
```javascript
import "@hotwired/turbo-rails"
import "controllers"
```

Create/update `app/javascript/controllers/index.js`:
```javascript
import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

Create `app/javascript/controllers/application.js`:
```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
```

#### Step 4: Update Existing Stimulus Controllers

Update each controller to use importmap-compatible imports:

**`app/javascript/controllers/drag_controller.js`:**
```javascript
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  // ... existing code
}
```

**`app/javascript/controllers/participant_complete_controller.js`:**
```javascript
import { Controller } from "@hotwired/stimulus"
import { Autocomplete } from "stimulus-autocomplete"

export default class extends Controller {
  // ... existing code
}
```

#### Step 5: Keep CSS Bundling for Bulma/Sass

Keep `cssbundling-rails` for CSS since Bulma uses Sass:

```ruby
# Gemfile - KEEP these for CSS
gem "cssbundling-rails"

# REMOVE jsbundling-rails
# gem "jsbundling-rails"  # Remove this
```

Update `Procfile.dev`:
```
web: bin/rails server -p 3000
css: yarn build:css:watch
```

Note: No longer need the `js: yarn build --watch` line.

#### Step 6: Update package.json

Simplify `package.json` to only include CSS dependencies:
```json
{
  "name": "pikaichu",
  "private": true,
  "dependencies": {
    "@fortawesome/fontawesome-free": "^7.1.0",
    "bulma": "^1.0.4",
    "bulma-divider": "^0.2.0",
    "bulma-timeline": "^3.0.5",
    "sass": "^1.94.2"
  },
  "scripts": {
    "build:css": "sass ./app/assets/stylesheets/application.bulma.scss ./app/assets/builds/application.css --no-source-map --load-path=node_modules && cp node_modules/bulma-divider/dist/css/bulma-divider.min.css node_modules/bulma-timeline/dist/css/bulma-timeline.min.css app/assets/builds/ && sass ./app/assets/stylesheets/fontawesome.scss ./app/assets/builds/fontawesome.css --no-source-map --load-path=node_modules && sed -i.bak 's|url(\"../webfonts/|url(\"../fonts/|g' app/assets/builds/fontawesome.css && rm -f app/assets/builds/fontawesome.css.bak",
    "build:css:watch": "sass ./app/assets/stylesheets/application.bulma.scss ./app/assets/builds/application.css --no-source-map --load-path=node_modules --watch"
  }
}
```

Remove these npm packages (now handled by importmap):
- `@hotwired/stimulus`
- `@hotwired/turbo-rails`
- `sortablejs`
- `stimulus-autocomplete`
- `esbuild`

#### Step 7: Update Layout

Update `app/views/layouts/application.html.erb`:
```erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <title>PiKaichu<%= @page_title ? " - #{@page_title}" : "" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "fontawesome", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "bulma-divider.min", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "bulma-timeline.min", "data-turbo-track": "reload" %>
    
    <%# Changed from javascript_include_tag to importmap %>
    <%= javascript_importmap_tags %>
  </head>
  <!-- ... rest of layout -->
</html>
```

#### Step 8: Update ApplicationController

Add `stale_when_importmap_changes`:
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes  # Add this line

  # ... rest of controller
end
```

#### Step 9: Update Gemfile

```ruby
# Remove
# gem "jsbundling-rails"

# Add
gem "importmap-rails"

# Keep
gem "cssbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
```

#### Step 10: Clean Up

Remove these files:
- `app/javascript/application.js` (will be recreated with importmap structure)
- `app/javascript/controllers/index.js` (will be recreated)

Run:
```bash
yarn remove @hotwired/stimulus @hotwired/turbo-rails sortablejs stimulus-autocomplete esbuild
bundle install
bin/rails importmap:install
```

### 3.3 Testing the Asset Migration

```bash
# Verify importmap configuration
bin/importmap audit
bin/importmap outdated

# Test in development
bin/dev

# Test asset precompilation
bin/rails assets:precompile
bin/rails assets:clean

# Run system tests to verify JavaScript functionality
bin/rails test:system
```

### 3.4 Potential Issues

1. **SortableJS compatibility:** Ensure the CDN version works with your usage
2. **stimulus-autocomplete:** May need vendoring if CDN version has issues
3. **Turbo compatibility:** Verify Turbo Streams still work correctly

If CDN versions have issues, vendor the packages:
```bash
bin/importmap vendor sortablejs
bin/importmap vendor stimulus-autocomplete
```

---

## Phase 4: Remove Deprecated Dependencies

### 4.1 Remove Devise

After Phase 2 is complete and tested:

1. Remove from Gemfile:
```ruby
# Remove: gem 'devise', github: 'heartcombo/devise', branch: 'main'
```

2. Delete Devise-related files:
   - `config/initializers/devise.rb`
   - `app/views/devise/` (entire directory)

3. Run migrations to clean up unused columns (optional, can keep for audit trail):
```ruby
class CleanupDeviseColumns < ActiveRecord::Migration[8.1]
  def change
    # Only if you want to remove legacy columns
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
    remove_column :users, :remember_created_at
    remove_column :users, :email # After migrating to email_address
    remove_column :users, :encrypted_password # After migrating to password_digest
  end
end
```

### 4.2 Remove Lockable-Related Columns

Since lockable is not used, clean up these columns:

```ruby
class RemoveLockableColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :unlock_token, :string
    remove_column :users, :locked_at, :datetime
    remove_column :users, :failed_attempts, :integer
  end
end
```

### 4.3 Review Other Dependencies

| Gem | Status | Recommendation |
|-----|--------|----------------|
| `activerecord-postgres_enum` | Keep | Rails 7+ has enum support but this gem handles edge cases |
| `audited` | Keep | No Rails 8 native equivalent |
| `pundit` | Keep | Best-in-class authorization |
| `statesman` | Keep | Robust state machine |
| `kaminari` | Keep | Well-maintained pagination |
| `mobility` | Keep | I18n for models |
| `caxlsx`, `caxlsx_rails` | Keep | Excel export functionality |
| `roo` | Keep | Excel import functionality |
| `acts_as_list` | Keep | List ordering |
| `country_select` | Keep | Country selection |
| `faraday` | Keep | HTTP client |
| `apparition` | Review | May need update or replacement for system tests |

### 4.3 Update Test Dependencies

Consider replacing `apparition` with modern alternatives:
```ruby
group :test do
  gem "capybara"
  gem "selenium-webdriver"
  # Remove: gem 'apparition'
end
```

---

## Phase 5: Code Quality and Best Practices

### 5.1 Add Modern Rails Features

#### Add `allow_browser` to ApplicationController
```ruby
allow_browser versions: :modern
```

#### Add `stale_when_importmap_changes` (if using importmap)
```ruby
stale_when_importmap_changes
```

#### Use `normalizes` for data normalization
```ruby
class User < ApplicationRecord
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
```

### 5.2 Controller Improvements

Add rate limiting where appropriate:
```ruby
rate_limit to: 10, within: 3.minutes, only: :create
```

### 5.3 Model Improvements

Use Rails 8's improved enum syntax:
```ruby
enum :form, {
  individual: 'individual',
  team: 'team',
  '2in1': '2in1',
  matches: 'matches',
}, prefix: :form
```

---

## Phase 6: Final Cleanup

### 6.1 Remove Unused Files

- [ ] `config/initializers/new_framework_defaults_7_1.rb`
- [ ] `config/initializers/devise.rb` (after Phase 2)
- [ ] `app/views/devise/` directory (after Phase 2)
- [ ] `app/controllers/turbo_controller.rb` (if only used for Devise)

### 6.2 Update Documentation

- [ ] Update README.md with new setup instructions
- [ ] Update any deployment documentation
- [ ] Document new authentication flow

### 6.3 Final Testing

```bash
# Full test suite
bin/rails test
bin/rails test:system

# Security audit
bin/brakeman
bin/bundler-audit

# Code quality
bin/rubocop
```

---

## Migration Timeline

| Phase | Duration | Risk Level | Dependencies |
|-------|----------|------------|--------------|
| Phase 1 | 1-2 days | Low | None |
| Phase 2 | 4-6 days | High | Phase 1 (includes Confirmable implementation) |
| Phase 3 | 2-3 days | Medium | None (can be done in parallel with Phase 2) |
| Phase 4 | 1 day | Low | Phase 2, Phase 3 |
| Phase 5 | 1 day | Low | None |
| Phase 6 | 1 day | Low | All phases |

**Total estimated time:** 10-14 days

---

## Rollback Strategy

Each phase should be on a separate branch:
- `modernization/phase-1-infrastructure`
- `modernization/phase-2-authentication`
- `modernization/phase-3-assets`
- `modernization/phase-4-cleanup`
- `modernization/phase-5-best-practices`
- `modernization/phase-6-final`

If issues arise, revert to the previous working branch.

---

## Resolved Questions

1. **Email Confirmation:** ✅ YES - Users must confirm their email before accessing the app

2. **Account Locking:** ❌ NO - Not needed, can be removed

3. **Remember Me:** Sessions will persist via permanent signed cookies (Rails 8 default)

4. **Asset Pipeline:** ✅ Migrate to importmap-rails (Rails-native approach)

5. **Password Requirements:** 6-128 characters (keep current Devise settings)

6. **User Registration:** ✅ YES - Users can self-register

7. **Password Migration:** ✅ VERIFIED COMPATIBLE
   - Both Devise and `has_secure_password` use bcrypt with identical hash format
   - Simply rename `encrypted_password` → `password_digest`
   - **Existing passwords will continue to work without user action**

---

## References

- [Rails 8 Authentication Generator](https://guides.rubyonrails.org/getting_started.html#authentication)
- [Rails 8 Release Notes](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required)
- [Solid Queue](https://github.com/basecamp/solid_queue)
- [Solid Cache](https://github.com/rails/solid_cache)
- [Solid Cable](https://github.com/rails/solid_cable)
- [Importmap Rails](https://github.com/rails/importmap-rails)
