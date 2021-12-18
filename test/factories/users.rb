FactoryBot.define do
  sequence :email do |n|
    "user-#{n}@example.org"
  end

  factory :user do
    email { generate(:email) }
    password { "password" }
    confirmed_at { DateTime.now }
  end
end