class Result < ApplicationRecord
  audited

  belongs_to :participant

  validate :cannot_update_if_finalized, on: :update

  enum status: {
    hit: 'hit',
    miss: 'miss',
    unknown: 'unknown'
  }, _prefix: :status

  human_enum :status

  def known?
    status_hit? || status_miss?
  end

  def marked?
    !status.nil?
  end

  def empty?
    status.nil?
  end

  def cannot_update_if_finalized
    #  Make sure once final is true the object cannot be changed anymore,
    #  even the final boolean
    finalized = final? && changes['final'].nil? || !final? && changes['final']&.first

    errors.add(:result_id, "is already finalized") if finalized
  end
end
