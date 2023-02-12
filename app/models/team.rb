class Team < ApplicationRecord
  include Scoreable
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

  def create_empty_score(match_id: nil)
    scores.create!(team_id: id, match_id: match_id)
  end


  def score(match_id = nil)
    scores.find_by(match_id: match_id)
  end


  def to_ascii(match_id = nil)
    [
    "#{shortname}: #{score(match_id)&.to_ascii}",
    participants.map { |participant| "  #{participant.to_ascii(match_id)}" },
    ].flatten.join("\n")
  end
end
