class ParticipatingDojo < ApplicationRecord
  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, -> { order lastname: :asc, firstname: :asc }, dependent: :destroy
end
