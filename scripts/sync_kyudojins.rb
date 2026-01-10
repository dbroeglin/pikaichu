options = {
  request: {
    open_timeout: 15,
    timeout: 120
  },
  headers: {
    'TokenHeader' => ENV.fetch('FEDERATION_API_TOKEN', nil),
    'Accept-Encoding' => 'gzip, deflate, br',
    'Accept' => 'application/json'
  }
}

conn = Faraday.new(options) do |faraday|
  faraday.response :json
end

response = conn.get("#{ENV.fetch('FEDERATION_API_URL', nil)}/kyudo_prod/api.svc/licenciesSaison/2024_2025")
body = response.body

kyudojins = body['licencies'].map do |licencie|
    {
      firstname: licencie['prenom'],
      lastname: licencie['nom'],
      license_id: licencie['numeroLicence'],
      federation_club: licencie['licences'].first['clubNom'],
      federation_country_code: 'fr'
    }
  end

puts "Number of kyudojins to update: #{kyudojins.size}"
result = Kyudojin.upsert_all(
  kyudojins,
  unique_by: [ :license_id ],
  update_only: [ :firstname, :lastname, :federation_club, :federation_country_code ],
  record_timestamps: true
)

# nb_deleted = Kyudojin.where.not(id: result.rows.map(&:first)).delete_all

puts "Upserted #{result.rows.size} kyudojins."

#
# The following code uses firstname & lastname as primary key for updates
#

# body['licencies'].map do |licencie|
#   firstname = licencie['prenom']
#   lastname = licencie['nom']
#   license_id = licencie['numeroLicence']
#   federation_club = licencie['licences'].first['clubNom']

#   kyudojin = Kyudojin.where(firstname: firstname, lastname: lastname).first
#   if kyudojin
#     puts "Updating Kyudojin #{firstname} #{lastname} #{license_id} #{federation_club}..."
#     kyudojin.update(license_id: license_id, federation_club: federation_club)
#     kyudojin.id
#   else
#     puts "Creating Kyudojin #{firstname} #{lastname} #{license_id} #{federation_club}..."
#     kyudojin = Kyudojin.create!(
#       firstname: firstname,
#       lastname: lastname,
#       license_id: license_id,
#       federation_club: federation_club,
#       federation_country_code: 'fr'
#     )
#   end
#   [kyudojin.id]
# end
