class Team < ApplicationRecord
  audited

  belongs_to :participating_dojo
  has_many :participants,
           -> { order index_in_team: :asc, lastname: :asc, firstname: :asc },
           dependent: :destroy,
           inverse_of: :team
  has_many :results, through: :participants

  validates :shortname,
            presence: true,
            uniqueness: {
              scope: :participating_dojo,
              case_sensitive: false,
            }

  validates :index,
            uniqueness: {
              scope: :participating_dojo,
              allow_blank: true,
            }

  def score(final = true)
    if final
      results.select { |r| r.final? && r.status_hit? }.size
    else
      results.select(&:status_hit?).size
    end
  end
end
