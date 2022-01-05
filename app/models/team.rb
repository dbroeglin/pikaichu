class Team < ApplicationRecord
  audited

  belongs_to :participating_dojo
  has_many :participants,
           -> { order index_in_team: :asc, lastname: :asc, firstname: :asc },
           dependent: :destroy
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

  def score
    results.select { |r| r.status == 'hit' }.size
  end
end
