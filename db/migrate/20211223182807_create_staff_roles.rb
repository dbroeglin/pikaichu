class CreateStaffRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :staff_roles do |t|
      t.string :code
      t.string :label
      t.string :description

      t.timestamps
    end
  end
end
