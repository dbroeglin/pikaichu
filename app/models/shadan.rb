class Shadan < ApplicationRecord
  audited

  belongs_to :participating_dojo

  def scores
    @participants = @participating_dojo.participants
    @scores = @participants.map do |participant|
      participant.scores.last.results.map(&:status_code)
    end
  end
end
