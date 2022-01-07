FactoryBot.define do
  factory :user do
    firstname { Faker::Name.first_name  }
    lastname { Faker::Name.last_name }
    email {
       "#{ ActiveSupport::Inflector.parameterize "#{firstname}.#{lastname}", separator: "."}@example.org"
    }
    password { "password" }
    confirmed_at { DateTime.now }
  end
end