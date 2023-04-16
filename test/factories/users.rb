FactoryBot.define do
  factory :user do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email do
      "#{ActiveSupport::Inflector.parameterize "#{firstname}.#{lastname}", separator: '.'}@test.kyudo.fr"
    end
    password { "password" }
    confirmed_at { DateTime.now }
    admin { false }
  end
end