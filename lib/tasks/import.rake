require 'csv'

task :import => :environment do
  Rails.logger.level = 0

  raise "Please define IMPORT_CSV_FILE" unless ENV['IMPORT_CSV_FILE']

  data = File.read(ENV['IMPORT_CSV_FILE'], encoding: 'bom|utf-8')
  lines = 0

  Kyudojin.delete_all
  CSV.parse(data,
      headers: true,
      col_sep: ';'
  ) do |row|
    Kyudojin.create!(
      lastname: row['IDE_NOM_IDENTIF'],
      firstname: row['IDE_PRENOM'],
      federation_id: row['IDE_CODE'],
      federation_country_code: 'FR',
      federation_club: row['dbo_T_CLUB_CLUB_DESIGNATION'],
    )

    lines += 1
  end

  puts "Imported #{lines} lines"
end