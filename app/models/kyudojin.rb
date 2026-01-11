class Kyudojin < ApplicationRecord
  # Rails 8: Normalize fields before save
  normalizes :firstname, :lastname, with: ->(name) { name.strip.titlecase }
  normalizes :license_id, with: ->(value) { value&.strip&.upcase }

  scope :containing, lambda { |query|
    where("lastname ILIKE ? OR firstname ILIKE ?", "%#{query}%", "%#{query}%").order(:lastname, :firstname)
  }

  def display_name
    "#{firstname} #{lastname}"
  end
end
