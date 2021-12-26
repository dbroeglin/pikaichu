class CreateParticipants < ActiveRecord::Migration[6.1]
  def change
    create_table :participants do |t|
      t.string :firstname
      t.string :lastname
      t.references :participating_dojo, null: false, foreign_key: true

      t.timestamps
    end
  end
end
