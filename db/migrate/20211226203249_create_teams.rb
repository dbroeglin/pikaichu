class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.integer :index
      t.belongs_to :participating_dojo, null: false, foreign_key: true

      t.timestamps
    end
    add_index :teams, [:participating_dojo_id, :index], unique: true, name: "by_participating_dojo_index"

    add_reference :participants, :team, foreign_key: true
    add_column :taikais, :individual, :boolean, default: true
  end
end
