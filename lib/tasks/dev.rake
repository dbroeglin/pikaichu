if Rails.env.development? || Rails.env.test?
    require "factory_bot"

    namespace :dev do
      desc "Sample data for local development environment"
      task prime: "db:setup" do
        include FactoryBot::Syntax::Methods

        create(:user, email: "jean.bon@example.org", password: "password")

        create(:taikai,
          shortname: "chablais-2021",
          name: "Tournoi du Chablais 2021",
          description: "",
          start_date: '2021-12-18',
          end_date: '2021-12-18'
        )

        create_list(:taikai, 10)
        create_list(:dojo, 10)
      end
    end
  end