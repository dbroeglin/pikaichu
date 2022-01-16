class AddShortnameIndexToTeams < ActiveRecord::Migration[7.0]
  def change
    add_index :teams, [:participating_dojo_id, :shortname], unique: true, name: "by_teams_shortname"
  end
end
