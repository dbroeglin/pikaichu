FactoryBot.define do
  factory :match do
    taikai_id { 1 }
    team1_id { 1 }
    team2_id { 1 }
    level { 1 }
    index { 1 }
    winner { 1 }
  end
end
