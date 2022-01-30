class AddTaikaiTypeToTaikais < ActiveRecord::Migration[7.0]
  def change
    create_enum :taikai_form, %w[individual team 2in1]

    add_column :taikais, :form, :taikai_form, default: 'individual'
    add_index :taikais, :form, unique: false, name: 'taikais_by_form'

    Taikai.reset_column_information

    Taikai.all.each do |taikai|
      taikai.form = taikai.form_individual? ? 'individual' : 'team'
      taikai.save
    end

    change_table :taikais, bulk: true do |t|
      t.change_default :form, from: 'individual', to: nil
      t.remove :individual, type: :boolean
    end
  end
end
