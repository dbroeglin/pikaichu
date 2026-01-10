class AddShortnameIndexToTakais < ActiveRecord::Migration[7.0]
  def change
    add_index :taikais, [ :shortname ], unique: true, name: "by_taikais_shortname"
  end
end
