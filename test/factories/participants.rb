FactoryBot.define do
  sequence :title, [nil, nil, nil, nil, "R"].cycle
  sequence :level, ["mudan", "1", "2", "3", "4", "5"].cycle

  factory :participant do
    firstname { Faker::Name.first_name  }
    lastname { Faker::Name.last_name }
    title
    level

    after(:create) do |participant, evaluator|
      participant.generate_empty_results
      participant.reload
    end
  end
end
