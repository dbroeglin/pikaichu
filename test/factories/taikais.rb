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

    shortname { generate(:taikai_short_name) }
    name { generate(:taikai_name) }
    start_date { 5.days.from_now }
    end_date { 5.days.from_now }
    description { Faker::Lorem.paragraph }
    distributed { true }
    individual { false }
    current_user { user }

    factory :taikai_with_participating_dojo do
      after(:create) do |taikai, evaluator|
        Dojo.all.each do |dojo|
          create(:participating_dojo_with_participants, dojo: dojo, taikai: taikai)
        end

        users = User.all.to_a
        create(:staff, taikai: taikai,
          role: StaffRole.find_by_code(:chairman),
          user: users.pop)

        taikai.participating_dojos.each do |participating_dojo|
          create(:staff,
            taikai: taikai,
            role: StaffRole.find_by_code(:dojo_admin),
            user: users.pop,
            participating_dojo: participating_dojo)
          create(:staff,
            taikai: taikai,
            role: StaffRole.find_by_code(:marking_referee),
            user: users.pop,
            participating_dojo: participating_dojo)
          create(:staff,
              taikai: taikai,
              role: StaffRole.find_by_code(:yatori),
              participating_dojo: participating_dojo)
        end if evaluator.with_staff
        taikai.reload
      end
    end
  end
end