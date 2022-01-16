class ParticipatingDojo < ApplicationRecord
  audited

  belongs_to :taikai
  belongs_to :dojo
  has_many :participants, -> { order index: :asc, lastname: :asc, firstname: :asc },
           dependent: :destroy,
           inverse_of: :participating_dojo
  has_many :teams, -> { order index: :asc }, dependent: :destroy, inverse_of: :participating_dojo
  has_many :staffs, inverse_of: :participating_dojo, dependent: nil
end
