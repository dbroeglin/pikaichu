class AddIntermediateRankToParticipantAndTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :intermediate_rank, :integer

    add_column :teams, :intermediate_rank, :integer
  end
end
