class CreateScoreboards < ActiveRecord::Migration[7.2]
  def change
    create_table :scoreboards do |t|
      t.string :api_key
      t.integer :nb_participants
      t.references :participating_dojo, null: true, foreign_key: true

      t.timestamps
    end

    add_index :scoreboards, :api_key, unique: true
  end
end
