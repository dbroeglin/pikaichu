FactoryBot.define do
  factory :user do
    firstname { Faker::Name.first_name  }
    lastname { Faker::Name.last_name }
    email { "#{firstname}.#{lastname}@example.org".downcase }
    password { "password" }
    confirmed_at { DateTime.now }
  end
end