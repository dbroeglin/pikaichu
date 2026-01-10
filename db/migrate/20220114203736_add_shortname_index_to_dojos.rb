class AddShortnameIndexToDojos < ActiveRecord::Migration[7.0]
  def change
    add_index :dojos, [ :shortname ], unique: true, name: "by_shortname"
  end
end
