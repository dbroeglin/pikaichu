class AddRankToParticipantAndTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :rank, :integer

    add_column :teams, :rank, :integer
  end
end
