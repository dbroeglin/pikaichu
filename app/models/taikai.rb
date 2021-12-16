class Taikai < ApplicationRecord
    validates :shortname, presence: true, length: { minimum: 3, maximum: 20 }
    validates :name, presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true

    validates :distributed, acceptance: true

end
