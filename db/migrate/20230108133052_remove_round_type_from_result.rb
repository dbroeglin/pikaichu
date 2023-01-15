class RemoveRoundTypeFromResult < ActiveRecord::Migration[7.0]
  def change
    remove_column :results, :round_type
    drop_enum :round_type
  end
end
