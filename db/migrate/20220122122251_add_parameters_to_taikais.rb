class AddParametersToTaikais < ActiveRecord::Migration[7.0]
  def change
    change_table :taikais, bulk: true do |t|
      t.integer :num_targets, limit: 1, default: 6, null: false
      t.integer :total_num_arrows, limit: 1, default: 12, null: false
      t.integer :tachi_size, limit: 1, default: 3, null: false
    end
  end
end