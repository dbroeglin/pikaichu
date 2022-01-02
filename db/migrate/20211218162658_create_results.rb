class CreateResults < ActiveRecord::Migration[6.1]
  def change
    create_enum :result_status, ["hit", "miss", "unknown"]

    create_table :results do |t|
      t.references :participant, null: false, foreign_key: true
      t.integer :round
      t.integer :index
      t.enum :status, enum_type: :result_status, null: true

      t.timestamps
    end

    add_index :results, [:participant_id, :round, :index], unique: true, name: "by_participant_round_index"
  end
end
