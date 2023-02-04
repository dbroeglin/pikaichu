class Participant < ApplicationRecord
  include Scoreable
  audited

  acts_as_list column: :index_in_team, scope: :team, sequential_updates: true

  belongs_to :participating_dojo
  belongs_to :team, optional: true

  has_one :taikai, through: :participating_dojo
  belongs_to :kyudojin, optional: true
  has_many :results, through: :scores


  validates :firstname, :lastname, presence: true
  validates :kyudojin,
            uniqueness: {
              scope: :participating_dojo,
              allow_blank: true,
            }
  validates :index,
            uniqueness: {
              scope: :participating_dojo,
              allow_blank: true,
            }

  def display_name
    "#{firstname} #{lastname}"
  end

  def add_result(match_id, status, value)
    scores.find_by(match_id: match_id).add_result(status, value)
  end

  def first_score_results
    # TODO: review all usages and make less brittle
    scores.first&.results || []
  end

  def score(final = true, match_id = nil)
    score = scores.find_by(match_id: match_id)
    return Score.new(hits: 0, value: 0) if score.nil?

    scope = score.results
    if final
      results = scope.select { |r| r.final? && r.status_hit? }
    else
      results = scope.select(&:status_hit?)
    end
    Score.new(hits: results.size, value: results.map(&:value).compact.sum)
  end

  def marking?(match_id = nil)
    score = scores.find_by(match_id: match_id)
    if score.nil?
      return false
    end

    score.marking?
  end

  def defined_results?(match_id = nil)
    results.where('status IS NOT NULL').where(match_id: match_id).any?
  end

  def create_empty_score_and_results(match_id = nil)
    if defined_results?(match_id)
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end

    score = scores.create(participant_id: id, match_id: match_id)
    score.create_results taikai.num_rounds, taikai.num_arrows
    scores.reload

    results.reload
  end

  def finalized?
    scores.all?(&:finalized?)
  end
end
