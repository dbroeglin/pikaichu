require 'csv'

task :import => :environment do
  Rails.logger.level = 0

  raise "Please define KYUDOJINS_CSV_FILE" unless ENV['KYUDOJINS_CSV_FILE']
  raise "Please define DOJOS_CSV_FILE" unless ENV['DOJOS_CSV_FILE']


  kyudojins_data = File.read(ENV['KYUDOJINS_CSV_FILE'], encoding: 'bom|utf-8')
  dojos_data = File.read(ENV['DOJOS_CSV_FILE'], encoding: 'bom|utf-8')

  num_lines = 0
  num_inserted = 0

  #Kyudojin.delete_all
  CSV.parse(kyudojins_data,
      headers: true,
      col_sep: ';'
  ) do |row|
    attrs = {
      lastname: row['IDE_NOM_IDENTIF'],
      firstname: row['IDE_PRENOM'],
      federation_id: row['IDE_CODE'],
      federation_country_code: 'FR',
      federation_club: row['acronyme']
    }
    Kyudojin.upsert(attrs, unique_by: :federation_id)
    num_lines += 1
  end

  puts "Processed #{num_lines} lines, #{Kyudojin.count} kyudojins in database"


  num_lines = 0
  num_inserted = 0

  CSV.parse(dojos_data,
      headers: true,
      col_sep: ';'
  ) do |row|
    attrs = {
      shortname: row['sigle'],
      name: row['designation'],
      city: row['ville'],
      country_code: 'FR'
    }
    Dojo.upsert(attrs, unique_by: :shortname)
    num_lines += 1
  end

  puts "Processed #{num_lines} lines, #{Dojos.count} dojos in database"

end