class CreateParticipants < ActiveRecord::Migration[6.1]
  def change
    create_table :participants do |t|
      t.integer :index
      t.string :firstname
      t.string :lastname
      t.references :participating_dojo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :participants,
              %i[participating_dojo_id index],
              unique: true,
              name: 'participants_by_participating_dojo_index'
  end
end
