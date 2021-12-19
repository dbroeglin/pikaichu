FactoryBot.define do
    sequence :taikai_short_name do |n|
      "takai-#{n}"
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

      factory :factory_taikai_with_structure do
        after(:create) do |taikai, evaluator|
          Dojo.all.each do |dojo|
            create(:factory_participating_dojo_with_structure, dojo: dojo, taikai: taikai)
          end

          taikai.reload
        end
      end
    end
  end