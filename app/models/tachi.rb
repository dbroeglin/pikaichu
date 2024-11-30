class Tachi < ApplicationRecord
  audited

  belongs_to :participating_dojo
  belongs_to :match, optional: true

  def participants
    if match_id.nil?
      participating_dojo.participants.in_groups_of(participating_dojo.taikai.num_targets, false)[index - 1]
    else
      [match.team1&.participants, match.team2&.participants].compact.flatten
    end
  end

  def to_ascii(match_id = nil)
    [
      "#{round} - #{index} - #{finished ? 'finished' : 'not finished'}",
      match_id ? "  match_id: #{match_id}" : nil,
      participants.map { |participant| "  #{participant.to_ascii(match_id)}" },
    ].flatten.join("\n")
  end
end
