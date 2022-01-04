class ParticipatingDojo < ApplicationRecord
  audited

  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, -> { order index: :asc, lastname: :asc, firstname: :asc }, dependent: :destroy
  has_many :teams, -> { order index: :asc }, dependent: :destroy
  has_many :staffs
end
