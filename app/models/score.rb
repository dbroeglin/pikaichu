class Score < ApplicationRecord
  include Comparable

  # TODO: after migration
  # audited

  belongs_to :team, optional: true
  belongs_to :participant, optional: true

  validate :team_xor_participant
  validates :hits, :value, presence: true

  def <=>(other)
    result = value <=> other.value
    return result if result != 0
    hits <=> other.hits
  end

  def ==(other)
    return false if other.nil?

    hits == other.hits && value == other.value
  end

  def +(other)
    Score.new(hits: hits + other.hits, value: value + other.value)
  end

  def -@
    Score.new(hits: -hits, value: -value)
  end

  def to_s
    "Score: #{value} / #{hits}"
  end


  private

  def team_xor_participant
    return if team_id.nil? ^ participant_id.nil?

    errors.add(:base, 'Specify a participant or a team, not both: ' + self.inspect)
  end
end