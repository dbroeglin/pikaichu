class ChangeStaffRoleLabelColumnForMobility < ActiveRecord::Migration[7.0]
  def change
    change_table :staff_roles, bulk: true do |t|
      t.index [ :code ], unique: true, name: "by_staff_roles_code"

      t.remove :label, type: :string
      t.remove :description, type: :string
      t.column :label, :json, null: false, default: {}
      t.column :description, :json, null: false, default: {}
    end
  end
end
