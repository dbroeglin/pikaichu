class Result < ApplicationRecord
  belongs_to :participant

  enum status: {
    hit: 'hit',
    miss: 'miss',
  }, _prefix: :status

  human_enum :status
end
