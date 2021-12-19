FactoryBot.define do
  factory :participating_dojo do
    taikai { nil }
    dojo { nil }
    display_name { dojo.name }

    factory :participating_dojo_with_participants do
      transient do
        participant_count { 3 }
      end

      after(:create) do |participating_dojo, evaluator|
        create_list(:participant, evaluator.participant_count, participating_dojo: participating_dojo)

        participating_dojo.reload
      end
    end
  end
end
