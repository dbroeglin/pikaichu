FactoryBot.define do
  factory :staff do
    firstname { Faker::Name.first_name  }
    lastname { Faker::Name.last_name }
    role { nil }
    user { nil }
  end
end
