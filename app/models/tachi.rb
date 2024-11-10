class Tachi < ApplicationRecord
  audited

  belongs_to :participating_dojo

  def participants
    participating_dojo.participants.in_groups_of(participating_dojo.taikai.num_targets)[index - 1]
  end

  def to_ascii(match_id = nil)
    [
      "#{round} - #{index} - #{finished ? 'finished' : 'not finished'}",
      participants.map { |participant| "  #{participant.to_ascii(match_id)}" },
    ].flatten.join("\n")
  end
end
