FactoryBot.define do
  sequence :dojo_shortname do |n|
    "dojo-#{n}"
  end

  sequence :dojo_name do |n|
    "Dojo #{n}"
  end

  factory :dojo do
    shortname { generate(:dojo_shortname) }
    name { generate(:dojo_name) }
    country_code { "FR" }
  end
end