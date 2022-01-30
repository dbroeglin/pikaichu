if Rails.env.development? || Rails.env.test?
  Faker::Config.random = Random.new(42)
end