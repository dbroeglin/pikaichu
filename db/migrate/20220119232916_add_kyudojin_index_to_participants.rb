class AddKyudojinIndexToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_index :participants,
              [:participating_dojo_id, :kyudojin_id],
              unique: true,
              name: "by_participants_participating_dojo_kyudojin"
  end
end
