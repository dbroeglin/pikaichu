FactoryBot.define do
  factory :session do
    user { nil }
    ip_address { "MyString" }
    user_agent { "MyString" }
  end
end
