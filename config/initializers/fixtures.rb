Faker::Config.random = Random.new(42) if Rails.env.development? || Rails.env.test?