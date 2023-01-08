module HasRankable
  extend ActiveSupport::Concern

  included do

    def ranked_participants
      participants.count
    end

    def ranked_teams
      teams.count
    end
  end

  class_methods do
  end
end