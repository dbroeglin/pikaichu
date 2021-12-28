FactoryBot.define do
    sequence :taikai_short_name do |n|
      "taikai-#{n}"
    end

    sequence :taikai_name do |n|
      "Taikai #{n}"
    end

    factory :taikai do
      transient do
        is_individual { true }
      end
      transient do
        user { nil }
      end

      shortname { generate(:taikai_short_name) }
      name { generate(:taikai_name) }
      start_date { 5.days.from_now }
      end_date { 5.days.from_now }
      distributed { true }
      individual { is_individual }
      current_user { user }

      factory :taikai_with_participating_dojo do
        after(:create) do |taikai, evaluator|
          Dojo.all.each do |dojo|
            create(:participating_dojo_with_participants, dojo: dojo, taikai: taikai,
                   is_individual: evaluator.is_individual)
          end

          create(:staff, taikai: taikai, role: StaffRole.find_by_code(:marking_referee), user: User.last)
          create(:staff, taikai: taikai, role: StaffRole.find_by_code(:yatori))

          taikai.reload
        end
      end
    end
  end