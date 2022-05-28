class AddScoringTypeToTaikai < ActiveRecord::Migration[7.0]
  def change
    create_enum :taikai_scoring, %w[kinteki enteki]

    add_column :taikais, :scoring, :taikai_scoring, default: 'kinteki'
    add_index :taikais, :scoring, unique: false, name: 'taikais_by_scoring'
  end
end
