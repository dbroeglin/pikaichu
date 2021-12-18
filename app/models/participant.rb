class Participant < ApplicationRecord
  belongs_to :participating_dojo
  has_many :results, dependent: :destroy
end
