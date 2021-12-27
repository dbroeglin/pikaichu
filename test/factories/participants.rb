FactoryBot.define do
  factory :participant do
    firstname { Faker::Name.first_name  }
    lastname { Faker::Name.last_name }
    participating_dojo { nil }
    team { nil }

    after(:create) do |participant, evaluator|
      participant.generate_empty_results

      participant.reload
    end
  end
end
