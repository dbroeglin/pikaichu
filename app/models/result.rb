class Result < ApplicationRecord
  audited

  belongs_to :participant
  belongs_to :match, optional: true

  validate :cannot_update_if_finalized, on: :update

  enum status: {
    hit: 'hit',
    miss: 'miss',
    unknown: 'unknown'
  }, _prefix: :status

  human_enum :status

  enum round_type: {
    normal: 'normal',
    tie_break: 'tie_break',
  }, _prefix: :round_type

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

  # TODO: remove me when tie-break is fully implemented
  def self.tie_break(taikai_shortname, lastname, index, status)
    taikai = Taikai.find_by(shortname: taikai_shortname)

    taikai.participants
      .find_by(lastname: lastname)
      .results.create(round: taikai.num_rounds + 1, index: index, final: true, round_type: 'tie_break', status: status)
  end
end
