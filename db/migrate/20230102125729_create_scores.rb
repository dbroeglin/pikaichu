class CreateScores < ActiveRecord::Migration[7.0]
  def change
    create_table :scores do |t|
      t.references :participant, null: true, foreign_key: true

      t.references :team, null: true, foreign_key: true
      t.references :match, null: true, foreign_key: true

      t.integer :hits
      t.integer :value

      t.integer :tie_break_hits
      t.integer :tie_break_value

      t.timestamps
    end

    add_index :scores, [:team_id, :match_id], unique: true, name: "by_team_id_match_id"
    add_index :scores, [:participant_id], unique: true, name: "by_participant_id"
  end
end
