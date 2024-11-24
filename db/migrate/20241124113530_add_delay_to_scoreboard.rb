class AddDelayToScoreboard < ActiveRecord::Migration[7.2]
  def change
    add_column :scoreboards, :delay, :integer, null: false, default: 15
  end
end
