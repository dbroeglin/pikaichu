class CreateDojos < ActiveRecord::Migration[6.1]
  def change
    create_table :dojos do |t|
      t.string :shortname
      t.string :name
      t.string :country_code

      t.timestamps
    end
  end
end
