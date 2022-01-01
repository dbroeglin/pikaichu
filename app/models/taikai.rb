class Taikai < ApplicationRecord
  has_many :staffs, dependent: :destroy
  has_many :participating_dojos, -> { order display_name: :asc }, dependent: :destroy
  has_many :participants, through: :participating_dojos

  validates :shortname,
            presence: true, length: { minimum: 3, maximum: 32 },
            uniqueness: { case_sensitive: false },
            format: { with: /\A(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)\z/, message: "only allows letters, numbers and dashes in the middle" }
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  attr_accessor :current_user
  after_create do
    throw "current_user must be set at creation time" unless self.current_user
    self.staffs.create!(user: self.current_user, role: StaffRole.find_by_code(:admin))
  end

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