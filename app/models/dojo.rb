class Dojo < ApplicationRecord
  validates :shortname, presence: true, length: { minimum: 3, maximum: 32 }
  validates :name, presence: true
  validates :country, presence: true

  attr_accessor :toto


  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end

end
