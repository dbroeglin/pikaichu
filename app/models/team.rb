class Team < ApplicationRecord
  belongs_to :participating_dojo
  has_many :participants, dependent: :destroy

  validates :index, uniqueness: { scope: :participating_dojo,
    message: "Should be unique" }, presence: true

  def ensure_next_index
    if self.index.blank?
      self.index = (participating_dojo.teams.maximum(:index) || 0) + 1
    end
  end
end
