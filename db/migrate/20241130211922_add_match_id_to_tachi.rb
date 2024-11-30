class AddMatchIdToTachi < ActiveRecord::Migration[7.2]
  def change
    add_reference :tachis, :match, foreign_key: true, null: true
  end
end
