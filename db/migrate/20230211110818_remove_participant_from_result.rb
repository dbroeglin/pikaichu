class RemoveParticipantFromResult < ActiveRecord::Migration[7.0]
  def change
    remove_column :results, :participant_id
  end
end
