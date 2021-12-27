class Participant < ApplicationRecord
  belongs_to :participating_dojo
  belongs_to :team, optional: true
  has_many :results, -> { order(round: :asc, index: :asc) }, dependent: :destroy
  has_one :taikai, through: :participating_dojo

  def display_name
    "#{firstname} #{lastname}"
  end

  def total
    results.select {|r| r.status == 'hit' }.size
  end

  def find_undefined_results
    results.where("status IS NULL")
  end

  def generate_empty_results
    if results.where("status IS NOT NULL").any?
      throw "Defined result(s) already exist(s) for #{id} (#{display_name})" # TODO
    end
    results.destroy_all

    now = DateTime::now
    num_arrows = taikai.num_arrows
    hashes = (1..taikai.num_rounds).map do |round_index|
      (1..num_arrows).map do |index|
        { participant_id: id, round: round_index, index: index,
          created_at: now, updated_at: now }
      end
    end.flatten
    results.insert_all hashes
  end
end
