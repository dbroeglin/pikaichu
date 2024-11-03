class CreateShadan < ActiveRecord::Migration[7.2]
  def change
    create_table :shadans do |t|
      t.integer :index, null: false
      t.integer :round, null: false
      t.boolean :finished, null: false, default: false
      t.references :participating_dojo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shadans, %i[participating_dojo_id index round], unique: true
  end
end
