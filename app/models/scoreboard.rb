class Scoreboard < ApplicationRecord
  belongs_to :participating_dojo, optional: true

  def shadan
    participating_dojo.current_shadan
  end
end
