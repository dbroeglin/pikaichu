class Participant < ApplicationRecord
  belongs_to :participating_dojo
  has_many :results, dependent: :destroy

  def display_name
    "#{firstname} #{lastname}"
  end
end
