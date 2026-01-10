FactoryBot.define do
  factory :staff_role do
    code { "code" }
    label_fr { code.gsub(/_/, " ").capitalize }
    description_fr { "Description de #{code}" }
    label_en { code.capitalize }
    description_en { "Description of #{code}" }
  end
end
