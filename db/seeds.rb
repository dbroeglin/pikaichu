# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

StaffRole.create!(
  [
    { code: :taikai_admin, label_fr: 'Administrateur', label_en: 'Administrator', description_fr: 'Administrateur', description_en: 'Administrator' },
    { code: :dojo_admin, label_fr: 'Administrateur de club', label_en: 'Dojo Administrator', description_fr: 'Administrateur de club', description_en: 'Dojo Administrator' },
    { code: :chairman, label_fr: 'Directeur du tournoi', label_en: 'Chairman', description_fr: 'Directeur du tournoi', description_en: 'Chairman' },
    { code: :marking_referee, label_fr: 'Enregistreur', label_en: 'Marking Referee', description_fr: 'Enregistreur', description_en: 'Marking Referee' },
    { code: :shajo_referee, label_fr: 'Juge de shajo', label_en: 'Shajo Referee', description_fr: 'Juge de shajo', description_en: 'Shajo Referee' },
    { code: :yatori, label_fr: 'Yatori', label_en: 'Yatori', description_fr: 'Yatori', description_en: 'Yatori' },
    { code: :target_referee, label_fr: 'Juge de Cible', label_en: 'Target Referee', description_fr: 'Juge de Cible', description_en: 'Target Referee' },
    { code: :operations_chairman, label_fr: 'Responsable Logistique', label_en: 'Operations Chairman', description_fr: 'Responsable Logistique', description_en: 'Operations Chairman' }
  ]
)
