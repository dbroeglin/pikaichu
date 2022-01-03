class Result < ApplicationRecord
  belongs_to :participant

  enum status: {
    hit: 'hit',
    miss: 'miss',
    unknown: 'unknown'
  }, _prefix: :status

  human_enum :status

  def known?
    status_hit? || status_miss?
  end
end
