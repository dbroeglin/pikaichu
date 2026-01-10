class Session < ApplicationRecord
  belongs_to :user

  before_create do
    self.user_agent = user_agent&.truncate(500)
  end
end
