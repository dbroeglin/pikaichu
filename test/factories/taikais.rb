FactoryBot.define do
    sequence :taikai_short_name do |n|
      "taikai-#{n}"
    end

    sequence :taikai_name do |n|
      "Taikai #{n}"
    end

    factory :taikai do
      shortname { generate(:taikai_short_name) }
      name { generate(:taikai_name) }
      start_date { 5.days.from_now }
      end_date { 5.days.from_now }
      distributed { true }

      factory :taikai_with_participating_dojo do
        after(:create) do |taikai, evaluator|
          Dojo.all.each do |dojo|
            create(:participating_dojo_with_participants, dojo: dojo, taikai: taikai)
          end

          taikai.reload
        end
      end
    end
  end