class CreateTaikais < ActiveRecord::Migration[6.1]
  def change
    create_table :taikais do |t|
      t.string :shortname
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
