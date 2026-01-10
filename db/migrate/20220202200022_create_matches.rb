class CreateMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :matches do |t|
      t.belongs_to :taikai, foreign_key: true, null: false
      t.belongs_to :team1, foreign_key: { to_table: :teams }, null: true
      t.belongs_to :team2, foreign_key: { to_table: :teams }, null: true
      t.integer :level, limit: 1, null: false
      t.integer :index, limit: 2, null: false
      t.integer :winner, limit: 1, null: true

      t.timestamps
    end

    add_belongs_to :results, :match, foreign_key: true, null: true
    add_enum_value :taikai_form, "matches"

    remove_index :results, [ :participant_id, :round, :index ], unique: true, name: "by_participant_round_index"
    add_index :results, [ :participant_id, :round, :index, :match_id ],
              unique: true, name: "by_participant_round_index_match_id"
  end
end
