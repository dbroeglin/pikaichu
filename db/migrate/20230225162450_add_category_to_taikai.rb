class AddCategoryToTaikai < ActiveRecord::Migration[7.0]
  def change
    add_column :taikais, :category, :string, null: true
  end
end
