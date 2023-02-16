class AddOverridenToResult < ActiveRecord::Migration[7.0]
  def change
    add_column :results, :overriden, :boolean, default: false
  end
end
