class CreateResults < ActiveRecord::Migration[6.1]
  def change
    create_enum :result_status, ["hit", "miss"]

    create_table :results do |t|
      t.references :participant, null: false, foreign_key: true
      t.integer :round
      t.integer :arrow_nb
      t.enum :status, enum_name: :result_status, null: false

      t.timestamps
    end
  end
end
