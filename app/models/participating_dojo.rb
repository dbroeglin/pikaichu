class ParticipatingDojo < ApplicationRecord
  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, dependent: :destroy
end
