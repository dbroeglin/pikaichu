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

  def score(final = true, match_id = nil)
    scope = results.where(round_type: 'normal')
    scope = scope.select { |r| r.match_id == match_id } if match_id
    results =
      if final
        scope.select { |r| r.final? && r.status_hit? }
      else
        scope.select(&:status_hit?)
      end

    Score.new(results.size, results.map(&:value).compact.sum)
  end

  def tie_break_score(final = true, match_id = nil)
    scope = results.where(round_type: 'tie_break')
    scope = scope.select { |result| result.match_id == match_id }
    results =
      if final
        scope.select { |r| r.final? && r.status_hit? }
      else
        scope.select(&:status_hit?)
      end

    Score.new(results.size, results.map(&:value).compact.sum)
  end
end
