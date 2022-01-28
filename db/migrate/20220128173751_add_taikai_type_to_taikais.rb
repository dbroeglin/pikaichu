class AddTaikaiTypeToTaikais < ActiveRecord::Migration[7.0]
  def change
    create_enum :taikai_form, %w[individual team 2in1part1]

    add_column :taikais, :form, :taikai_form

    Taikai.reset_column_information

    Taikai.all.each do |taikai|
      taikai.form = taikai.form_individual? ? 'individual' : 'team'
      taikai.save
    end

    change_column_default :taikais, :form, nil
    remove_column :taikais, :individual
  end
end
