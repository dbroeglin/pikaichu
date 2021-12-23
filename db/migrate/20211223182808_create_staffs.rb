class CreateStaffs < ActiveRecord::Migration[7.0]
  def change
    create_table :staffs do |t|
      t.string :firstname
      t.string :lastname

      t.references :taikai, foreign_key: true, null: false
      t.references :role, foreign_key: { to_table: :staff_roles }, null: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
