if Rails.env.development? || Rails.env.test?
    require "factory_bot"

    namespace :dev do
      desc "Sample data for local development environment"
      task prime: "db:setup" do
        include FactoryBot::Syntax::Methods

        create(:user, email: "jean.bon@example.org")
        create_list(:user, 5)

        create_list(:dojo, 4)

        create(:factory_taikai_with_structure,
          shortname: "chablais-2021",
          name: "Tournoi du Chablais 2021",
          description: "",
          start_date: '2021-12-18',
          end_date: '2021-12-18',
          distributed: false
        )

        create_list(:factory_taikai_with_structure, 3)
      end
    end
  end