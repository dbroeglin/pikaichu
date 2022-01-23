class Participant < ApplicationRecord
  audited

  acts_as_list column: :index_in_team, scope: :team

  belongs_to :participating_dojo
  belongs_to :team, optional: true
  has_many :results, -> { order(round: :asc, index: :asc) }, inverse_of: :participant, dependent: :destroy do
    def round(index)
      where(round: index)
    end

    def first_empty
      self.find(&:empty?)
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

  def score(final = true)
    if final
      results.select { |r| r.final? && r.status_hit? }.size
    else
      results.select(&:status_hit?).size
    end
  end

  def finalized_score
    results.select { |r| r.final? && r.status == 'hit' }.size
  end

  def previous_round_finalized?(result)
    if result.round == 1
      true
    else
      results.round(result.round - 1).all?(&:final?)
    end
  end

  def marking?
    num_marked = results.count(&:marked?)
    num_finalized = results.count(&:final?)

    num_marked != participating_dojo.taikai.total_num_arrows &&
      (num_marked.zero? ||
        num_finalized == num_marked ||
          (num_marked % participating_dojo.taikai.num_arrows != 0))
  end

  def create_empty_results
    if results.where('status IS NOT NULL').any?
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end
    results.destroy_all

    now = DateTime.now
    hashes =
      (1..taikai.num_rounds).map do |round_index|
        (1..taikai.num_arrows).map do |index|
          {
            participant_id: id,
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
