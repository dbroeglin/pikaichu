class Taikai < ApplicationRecord
  has_many :participating_dojos, -> { order display_name: :asc }, dependent: :destroy

  validates :shortname, presence: true, length: { minimum: 3, maximum: 32 }
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def num_arrows
    @num_arrows ||= 4
  end

  def total_num_arrows
    @total_num_arrows ||= 12
  end

  def num_rounds
    total_num_arrows / num_arrows
  end
end
