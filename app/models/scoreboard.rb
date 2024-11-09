class Scoreboard < ApplicationRecord
  belongs_to :participating_dojo, optional: true

  def tachi
    participating_dojo.current_tachi
  end
end
