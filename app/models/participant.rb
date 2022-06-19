class Participant < ApplicationRecord
  audited

  acts_as_list column: :index_in_team, scope: :team, sequential_updates: true

  belongs_to :participating_dojo
  belongs_to :team, optional: true
  has_many :results, -> { order(round: :asc, index: :asc) }, inverse_of: :participant, dependent: :destroy do
    def round(index)
      where(round: index)
    end

    def first_empty
      self.find(&:empty?)
    end

    def normal
      where(round_type: 'normal')
    end

    def tie_break
      where(round_type: 'tie_break')
    end
  end
  has_one :taikai, through: :participating_dojo
  belongs_to :kyudojin, optional: true

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

  def score(final = true, match_id = nil)
    scope = results.where(round_type: 'normal')
    scope = scope.select { |result| result.match_id == match_id }
    if final
      results = scope.select { |r| r.final? && r.status_hit? }
    else
      results = scope.select(&:status_hit?)
    end
    Score.new(results.size, results.map(&:value).compact.sum)
  end

  def previous_round_finalized?(result)
    if result.round == 1
      true
    else
      results.round(result.round - 1).all?(&:final?)
    end
  end

  def marking?(match_id = nil)
    scope = results.select { |result| result.match_id == match_id }
    num_marked = scope.count(&:marked?)
    num_finalized = scope.count(&:final?)

    num_marked != participating_dojo.taikai.total_num_arrows &&
      (num_marked.zero? ||
        num_finalized == num_marked ||
          (num_marked % participating_dojo.taikai.num_arrows != 0))
  end

  def create_empty_results(match_id = nil)
    if results.where('status IS NOT NULL').where(match_id: match_id).any?
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end
    results.where(match_id: match_id).destroy_all

    now = DateTime.now
    hashes =
      (1..taikai.num_rounds).map do |round_index|
        (1..taikai.num_arrows).map do |index|
          {
            participant_id: id,
            match_id: match_id,
            round: round_index,
            index: index,
            created_at: now,
            updated_at: now,
          }
        end
      end.flatten
    results.insert_all hashes
    results.reload
  end
end
