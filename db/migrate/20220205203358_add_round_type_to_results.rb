class AddRoundTypeToResults < ActiveRecord::Migration[7.0]
  def change
    create_enum :round_type, %w[normal tie_break]

    add_column :results, :round_type, :round_type, null: false, default: 'normal'
  end
end
