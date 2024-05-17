class AddColumnLocaleToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :locale, :string, default: 'fr'
  end
end
