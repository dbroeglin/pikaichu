class Kyudojin < ApplicationRecord
  scope :containing, -> (query) {
    where("lastname ILIKE ? OR firstname ILIKE ?", "%#{query}%", "%#{query}%").order(:lastname, :firstname)
  }

  def display_name
    "#{firstname} #{lastname}"
  end
end
