FactoryBot.define do
  factory :team do
    participating_dojo { nil }
    sequence(:shortname) { |n| "Team #{n}" }

    factory :team_with_participants do
      transient do
        participant_count { 3 }
      end
      index { nil }

      after(:create) do |team, evaluator|

        create_list(:participant, evaluator.participant_count,
                    participating_dojo: team.participating_dojo,
                    team: team)
        team.reload
      end
    end
  end
end
