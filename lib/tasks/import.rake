require 'csv'

namespace :import do
  task staff_roles: :environment do
    StaffRole.find_by(code: :taikai_admin).update(label_fr: 'Administrateur', label_en: 'Administrator')
    StaffRole.find_by(code: :dojo_admin).update(label_fr: 'Administrateur de club', label_en: 'Dojo Administrator')
    StaffRole.find_by(code: :chairman).update(label_fr: 'Directeur du tournoi', label_en: 'Chairman')
    StaffRole.find_by(code: :marking_referee).update(label_fr: 'Enregistreur', label_en: 'Marking Referee')
    StaffRole.find_by(code: :shajo_referee).update(label_fr: 'Juge de shajo', label_en: 'Shajo Referee')
    StaffRole.find_by(code: :yatori).update(label_fr: 'Assistant Yatori', label_en: 'Yatori')
  end

  task fr: :environment do
    Rails.logger.level = 0

    raise "Please define KYUDOJINS_CSV_FILE" unless ENV['KYUDOJINS_CSV_FILE']
    raise "Please define DOJOS_CSV_FILE" unless ENV['DOJOS_CSV_FILE']

    kyudojins_data = File.read(ENV['KYUDOJINS_CSV_FILE'], encoding: 'bom|utf-8')
    dojos_data = File.read(ENV['DOJOS_CSV_FILE'], encoding: 'bom|utf-8')

    num_lines = 0

    # Kyudojin.delete_all
    CSV.parse(kyudojins_data,
              headers: true,
              col_sep: ';') do |row|
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

    CSV.parse(dojos_data,
              headers: true,
              col_sep: ';') do |row|
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
end