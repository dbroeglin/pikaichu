class Result < ApplicationRecord
  include ValidateChangeBasedOnState
  audited

  belongs_to :score
  belongs_to :match, optional: true

  ENTEKI_VALUES = [0, 3, 5, 7, 9, 10].freeze
  validates :status, presence: true, if: -> { value.present? }
  validates :value,
            if: -> { score.participant.taikai.scoring == 'enteki' },
            presence: true,
            inclusion: { in: ENTEKI_VALUES }
  validate :cannot_update_if_finalized, on: :update

  after_save do
    score.recalculate_individual_score
  end

  enum :status, {
    hit: 'hit',
    miss: 'miss',
    unknown: 'unknown'
  }, prefix: :status

  human_enum :status

  def status_code
    {
      'hit' => 'X',
      'miss' => 'O',
      'unknown' => '?'
    }[status.to_s]
  end

  def value=(value)
    super(value)
    return if value.nil?

    self.status = self.value.zero? ? 'miss' : 'hit'
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

  def override_status(status)
    self.status = status
    self.overriden = true if changes[:status]

    !changes[:status].nil?
  end

  def override_value(value)
    self.value = value
    self.overriden = true if changes[:value]

    !changes[:value].nil?
  end

  def rotate_value
    self.value = (Result::ENTEKI_VALUES + [0])
                 .each_cons(2)
                 .find { |pair| pair.first == self.value }
                 .last

    self
  end

  def cannot_update_if_finalized
    #  Make sure once final is true the object cannot be changed anymore,
    #  even the final boolean
    finalized = final? && changes['final'].nil? || !final? && changes['final']&.first

    errors.add(:base, :already_finalized) if finalized && !overriden
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

  delegate :taikai, to: :score
end
