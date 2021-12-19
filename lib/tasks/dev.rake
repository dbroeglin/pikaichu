if Rails.env.development? || Rails.env.test?
    require "factory_bot"

    namespace :dev do
      desc "Sample data for local development environment"
      task prime: "db:setup" do
        include FactoryBot::Syntax::Methods

        Faker::Config.random = Random.new(42)

        create(:user, email: "jean.bon@example.org")
        create_list(:user, 5)

        create_list(:dojo, 4)

        create(:taikai_with_participating_dojo,
          shortname: "c-2021",
          name: "Tournoi du C. 2021",
          description: "",
          start_date: '2021-12-18',
          end_date: '2021-12-18',
          distributed: false
        )

        create_list(:taikai_with_participating_dojo, 3)

        Taikai.find_by_shortname("taikai-1").participating_dojos.first.participants.each do |participant|
          participant.results.each_with_index do |result, index|
            result.status = Faker::Boolean.boolean(true_ratio: 0.3) ? :hit : :miss
            result.save
          end
        end
      end
    end
  end