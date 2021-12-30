class Team < ApplicationRecord
  belongs_to :participating_dojo
  has_many :participants,
           -> { order index_in_team: :asc, lastname: :asc, firstname: :asc },
           dependent: :destroy

  validates :index,
            uniqueness: {
              scope: :participating_dojo,
            },
            presence: true

  def ensure_next_index
    if self.index.blank?
      self.index = (participating_dojo.teams.maximum(:index) || 0) + 1
    end
  end
end
