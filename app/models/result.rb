class Result < ApplicationRecord
  audited

  belongs_to :score
  belongs_to :match, optional: true

  ENTEKI_VALUES = [0, 3, 5, 7, 9, 10]
  validates :status, presence: true, if: -> { value.present? }
  validates :value,
    if: -> { score.participant.taikai.scoring == 'enteki' },
    presence: true,
    inclusion: { in: ENTEKI_VALUES }
  validate :cannot_update_if_finalized, on: :update

  after_save do
    score.recalculate_individual_score if status_hit?
  end

  enum status: {
    hit: 'hit',
    miss: 'miss',
    unknown: 'unknown'
  }, _prefix: :status

  human_enum :status

  def value=(value)
    super(value)
    if !value.nil?
      self.status = self.value.zero? ? 'miss' : 'hit'
    end
  end

  def known?
    status_hit? || status_miss?
  end

  def marked?
    !status.nil?
  end

  def empty?
    status.nil?
  end

  def rotate_status(all_marked)
    self.status = case status
    when 'hit' then 'miss'
    when 'miss' then all_marked ? 'hit' : 'unknown'
    when 'unknown' then 'hit'
    else raise "Cannot change value of a result that has not been marked yet"
    end

    self
  end

  def rotate_value
    self.value = (Result::ENTEKI_VALUES + [0])
      .each_cons(2)
      .find {|pair| pair.first == self.value }
      .last

    self
  end

  def cannot_update_if_finalized
    #  Make sure once final is true the object cannot be changed anymore,
    #  even the final boolean
    finalized = final? && changes['final'].nil? || !final? && changes['final']&.first

    errors.add(:result_id, "is already finalized") if finalized
  end

  def to_s
    s = if status_hit?
      "◯"
    elsif status_miss?
      "⨯"
    elsif status_unknown?
      "?"
    else
      " "
    end
    if value
      "#{s}/#{value}"
    else
      s
    end
  end
end
