class CreateKyudojins < ActiveRecord::Migration[7.0]
  def change
    create_table :kyudojins do |t|
      t.string :lastname
      t.string :firstname
      t.string :federation_id
      t.string :federation_country_code
      t.string :federation_club

      t.timestamps
    end

    add_reference :participants, :kyudojin, foreign_key: true, null: true
  end
end
