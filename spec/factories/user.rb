FactoryBot.define do
    factory :user do
      email { "jean.bon@example.org"}
      password { "password" }
      confirmed_at { DateTime.now }
    end
  end