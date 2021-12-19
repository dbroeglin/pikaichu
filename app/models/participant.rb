class Participant < ApplicationRecord
  belongs_to :participating_dojo
  has_many :results, -> { order(round: :asc, index: :asc) }, dependent: :destroy

  def display_name
    "#{firstname} #{lastname}"
  end

  def taikai
    participating_dojo.taikai
  end

  def total
    results.select {|r| r.status == 'hit' }.size
  end

  def generate_empty_results
    if results.where("status IS NOT NULL").any?
      throw "Non empty results already exist for #{id} (#{display_name})"
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
