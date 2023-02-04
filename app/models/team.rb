class Team < ApplicationRecord
  include Rankable, Scoreable
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

  def display_name
    shortname
  end

  # This uses participant results
  def score(final = true, match_id = nil)
    scope = self.results
    scope = scope.select { |r| r.match_id == match_id } if match_id
    results =
      if final
        scope.select { |r| r.final? && r.status_hit? }
      else
        scope.select(&:status_hit?)
      end

    Score.new(hits: results.size, value: results.map(&:value).compact.sum)
  end
end
