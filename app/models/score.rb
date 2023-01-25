class Score < ApplicationRecord
  # TODO: after migration
  # audited
  include Comparable

  class PreviousRoundNotValidatedError < StandardError
    attr_reader :previous_round

    def initialize(message = nil, previous_round)
      super(message || "Round #{previous_round} has not been validated")
      @previous_round = previous_round
    end
  end

  class UnableToFindUndefinedResultsError < StandardError; end

  class ScoreValue
    attr_reader :hits, :value

    def initialize(hits:, value: nil)
      @hits, @value = hits, value
    end

    def eql?(other)
      return false if other.nil?

      hits == other.hits && value == other.value
    end

    def hash
      (hits + 100 * (value || 0)).hash
    end

    def to_s
      "Score(hits: #{hits}, value: #{value})"
    end
  end

  belongs_to :team, optional: true
  belongs_to :participant, optional: true
  has_many :results, -> { order(round: :asc, index: :asc) }, inverse_of: :score, dependent: :destroy do
    def round(index)
      where(round: index)
    end

    def first_empty
      self.find(&:empty?)
    end
  end

  validate :team_xor_participant
  validates :hits, :value, presence: true

  def add_result(status, value = nil)
    result = results.first_empty
    if result
      if previous_round_finalized?(result)
        result.update!(status: status, value: value)
      else
        raise PreviousRoundNotValidatedError::new([1, result.round - 1].min)
      end
    else
      raise UnableToFindUndefinedResultsError
    end

    result
  end

  def recalculate_score
    results.reload # TODO: improve performance
    hit_results = results.select(&:status_hit?)

    self.hits =  hit_results.size
    self.value = hit_results.map(&:value).compact.sum
  end

  def previous_round_finalized?(result)

    if result.round == 1
      true
    else
      results.round(result.round - 1).all?(&:final?)
    end
  end

  def score_value
    ScoreValue::new(hits: hits, value: value)
  end

  def marking?
    num_marked = results.count(&:marked?)
    num_finalized = results.count(&:final?)

    num_marked != results.count &&
      (num_marked.zero? ||
        num_finalized == num_marked ||
          (num_marked % participant.participating_dojo.taikai.num_arrows != 0))
          # TODO: could we reduce coupling here?
  end

  def create_results(num_rounds, num_arrows)
    now = DateTime.now
    hashes =
      (1..num_rounds).map do |round_index|
        (1..num_arrows).map do |index|
          {
            participant_id: participant.id,
            match_id: match_id,
            score_id: id,
            round: round_index,
            index: index,
            created_at: now,
            updated_at: now,
          }
        end
      end.flatten
    results.insert_all hashes
  end

  def <=>(other)
    return false if other.nil?

    result = value <=> other.value
    return result if result != 0

    hits <=> other.hits
  end

  def to_s
    "#{value} / #{hits}"
  end

  private

  def team_xor_participant
    return if team_id.nil? ^ participant_id.nil?

    errors.add(:base, 'Specify a participant or a team, not both: ' + self.inspect)
  end
end