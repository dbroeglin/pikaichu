class AddValueToResult < ActiveRecord::Migration[7.0]
  def change
    add_column :results, :value, :integer
  end
end
