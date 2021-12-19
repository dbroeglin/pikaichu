class CreateParticipatingDojos < ActiveRecord::Migration[6.1]
  def change
    create_table :participating_dojos do |t|
      t.string :display_name
      t.references :taikai, null: false, foreign_key: true
      t.references :dojo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :participating_dojos, [:taikai_id, :dojo_id], unique: true, name: "by_taikai_dojo"
  end
end
