class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.integer :index, null: true
      t.string :shortname, null: false
      t.belongs_to :participating_dojo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :teams,
              %i[participating_dojo_id index],
              unique: true,
              name: 'teams_by_participating_dojo_index'

    # Updates to "participants"

    add_reference :participants, :team, foreign_key: true

    add_column :participants, :index_in_team, :integer, null: true

    add_index :participants,
              %i[team_id index_in_team],
              unique: true,
              name: 'teams_by_team_index_in_team'
  end
end
