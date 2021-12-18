class Dojo < ApplicationRecord
  validates :shortname, presence: true, length: { minimum: 3, maximum: 32 }
  validates :name, presence: true
  validates :country_code, presence: true

  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end
end
