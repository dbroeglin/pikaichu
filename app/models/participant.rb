class Participant < ApplicationRecord
  belongs_to :participating_dojo
  belongs_to :team, optional: true
  has_many :results, -> { order(round: :asc, index: :asc) }, dependent: :destroy
  has_one :taikai, through: :participating_dojo

  validates :firstname, :lastname, presence: true
  validates :index,
            uniqueness: {
              scope: :participating_dojo,
              allow_blank: true,
            }

  validates :index_in_team,
            uniqueness: {
              scope: :team_id,
              allow_blank: true,
            },
            presence: {
              unless: -> { team_id.blank? }
            }

  def display_name
    "#{firstname} #{lastname}"
  end

  def total
    results.select { |r| r.status == 'hit' }.size
  end

  def find_undefined_results
    results.where('status IS NULL')
  end

  def generate_empty_results
    if results.where('status IS NOT NULL').any?
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end
    results.destroy_all

    now = DateTime.now
    hashes =
      (1..taikai.num_rounds).map do |round_index|
        (1..taikai.num_arrows).map do |index|
          {
            participant_id: id,
            round: round_index,
            index: index,
            created_at: now,
            updated_at: now,
          }
        end
      end.flatten
    results.insert_all hashes
  end
end
