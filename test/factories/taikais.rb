FactoryBot.define do
  sequence :taikai_short_name do |n|
    "taikai-#{n}"
  end

  sequence :taikai_name do |n|
    "Taikai #{n}"
  end

  factory :taikai do
    transient do
      user { nil }
    end
    transient do
      with_staff { true }
    end

    start_date { 5.days.from_now }
    end_date { 5.days.from_now }
    description { Faker::Lorem.paragraph }
    distributed { true }
    form { 'team' }
    current_user { user }
    total_num_arrows { 12 }
    scoring { 'enteki' }

    shortname do
      [ form, distributed ? "dist" : "local", total_num_arrows, scoring].join '-'
    end
    name do
      [ form, distributed ? "dist" : "local", total_num_arrows.to_s, scoring].map(&:capitalize).join ' '
    end

    factory :taikai_with_participating_dojo do
      after(:create) do |taikai, evaluator|
        Dojo.first(taikai.distributed ? 2 : 1).each_with_index do |dojo, index|
          create(:participating_dojo_with_participants,
            # Do not change display_name, used for fixture naming
            display_name: "Participating Dojo#{index + 1} #{taikai.name}",
            dojo: dojo,
            taikai: taikai)
        end

        create(:staff,
          taikai: taikai,
          role: StaffRole.find_by!(code: :chairman),
          user: User.find_by(email: 'vince.santo@test.kyudo.fr'))

        if evaluator.with_staff
          taikai.participating_dojos.first(1).each do |participating_dojo|
            create(:staff,
                   taikai: taikai,
                   role: StaffRole.find_by!(code: :dojo_admin),
                   user: User.find_by!(email: 'alain.terieur@test.kyudo.fr'),
                   participating_dojo: participating_dojo)
            create(:staff,
                   taikai: taikai,
                   role: StaffRole.find_by!(code: :shajo_referee),
                   user: User.find_by(email: 'pat.ronat@test.kyudo.fr'),
                   participating_dojo: participating_dojo)
            create(:staff,
                   taikai: taikai,
                   firstname: 'Larry',
                   lastname: 'Golade',
                   role: StaffRole.find_by!(code: :target_referee),
                   participating_dojo: participating_dojo)
          end
        end
        taikai.reload
      end
    end
  end
end