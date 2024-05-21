class RenameFederationIdToLicenseId < ActiveRecord::Migration[7.1]
  def change
    remove_index :kyudojins, [:federation_id], unique: true, name: "by_federation_id"

    rename_column :kyudojins, :federation_id, :license_id

    add_index :kyudojins, [:license_id], unique: true, name: "by_license_id"
    add_index :kyudojins, [:firstname, :lastname], name: "by_firstname_lastname"
    add_index :kyudojins, [:lastname, :firstname], name: "by_lastname_firstname"
  end
end
