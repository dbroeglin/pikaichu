FactoryBot.define do
  sequence(:shortname) { |n| "dojo-#{n}" }
  sequence(:name) { |n| "Dojo #{n}" }
  sequence :country_code, ["DE", "FR", "HK", "JP"].cycle

  factory :dojo do
    shortname
    name
    city { Faker::Address.city }
    country_code
  end
end