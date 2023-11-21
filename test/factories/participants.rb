FactoryBot.define do
  factory :participant do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    club { "" }
    participating_dojo { nil }
    team { nil }
    index_in_team { (team.participants.maximum(:index_in_team) || 0) + 1 if team }
  end
end
