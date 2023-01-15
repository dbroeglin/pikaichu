class Participant < ApplicationRecord
  include Rankable, Scoreable
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

  def score(final = true, match_id = nil)
    scope = scores.find_by(match_id: match_id).results
    if final
      results = scope.select { |r| r.final? && r.status_hit? }
    else
      results = scope.select(&:status_hit?)
    end
    Score.new(hits: results.size, value: results.map(&:value).compact.sum)
  end

  def marking?(match_id = nil)
    scope = scores.find_by(match_id: match_id).results
    num_marked = scope.count(&:marked?)
    num_finalized = scope.count(&:final?)

    num_marked != participating_dojo.taikai.total_num_arrows &&
      (num_marked.zero? ||
        num_finalized == num_marked ||
          (num_marked % participating_dojo.taikai.num_arrows != 0))
  end

  def defined_results?(match_id = nil)
    results.where('status IS NOT NULL').where(match_id: match_id).any?
  end

  def create_empty_score_and_results(match_id = nil)
    if defined_results?(match_id)
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end

    score = Score.create(participant_id: id, match_id: match_id)

    now = DateTime.now
    hashes =
      (1..taikai.num_rounds).map do |round_index|
        (1..taikai.num_arrows).map do |index|
          {
            participant_id: id,
            match_id: match_id,
            score_id: score.id,
            round: round_index,
            index: index,
            created_at: now,
            updated_at: now,
          }
        end
      end.flatten
    score.results.insert_all hashes
    scores.reload
    results.reload
  end
end
