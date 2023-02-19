class CreateTaikaiEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :taikai_events do |t|
      t.references :taikai, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :category
      t.text :message
      t.jsonb :data
      t.datetime :created_at
    end
  end
end
