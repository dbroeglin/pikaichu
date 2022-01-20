class AddClubToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :club, :string, default: "", null: false
  end
end
