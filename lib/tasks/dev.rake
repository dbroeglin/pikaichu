if Rails.env.development? || Rails.env.test?
  require "factory_bot"

  namespace :dev do
    desc "Sample data for local development environment"
    task prime: "db:setup" do
      include FactoryBot::Syntax::Methods

      Rails.logger.level = 0

      Faker::Config.random = Random.new(42)

      create(:user, firstname: "Jean", lastname: "Bon", admin: true)
      create_list(:user, 15)

      create(:staff_role, code: :taikai_admin,    label_fr: 'Administrateur',         label_en: 'Administrator')
      create(:staff_role, code: :dojo_admin,      label_fr: 'Administrateur de club', label_en: 'Dojo Administrator')
      create(:staff_role, code: :chairman,        label_fr: 'Directeur du tournoi',   label_en: 'Chairman')
      create(:staff_role, code: :marking_referee, label_fr: 'Enregistreur',           label_en: 'Marking Referee')
      create(:staff_role, code: :shajo_referee,   label_fr: 'Juge de shajo',          label_en: 'Shajo Referee')
      create(:staff_role, code: :yatori,          label_fr: 'Yatori',                 label_en: 'Yatori')
      # Add other staff roles

      create_list(:dojo, 3)

      create(:taikai_with_participating_dojo,
             shortname: "5WKT",
             name: "第五世界 九堂大会",
             description: "Fifth World Kyudo Taikai (Annecy)",
             start_date: '2021-12-18',
             end_date: '2021-12-18',
             distributed: false,
             individual: true,
             user: User.second,
             with_staff: false) # Do not generate additional staff

      create_list(:taikai_with_participating_dojo, 2, current_user: User.first)
      create_list(:taikai_with_participating_dojo, 2, individual: true, current_user: User.first)

      Taikai.find_by_shortname("taikai-1").participating_dojos.first.participants.each do |participant|
        participant.results.each do |result|
          result.status = Faker::Boolean.boolean(true_ratio: 0.3) ? :hit : :miss
          result.save
        end
      end
    end
  end
end