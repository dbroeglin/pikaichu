class Match < ApplicationRecord
  audited

  belongs_to :taikai
  belongs_to :team1, class_name: "Team", optional: true
  belongs_to :team2, class_name: "Team", optional: true
  has_many :results

  def score1(final = false)
    team1&.score final, id
  end

  def score2(final = false)
    team2&.score final, id
  end

  def is_winner?(index)
    winner == index
  end

  def assigned?
    team1 && team2
  end

  def finalized?
    !results.where(final: false).any?
  end

  def ordered_teams
    if is_winner? 1
      [team1, team2]
    else
      [team2, team1]
    end
  end

  def select_winner(winner)
    # TODO handle "small" final
    raise "Winner can be only 1 or 2" if winner < 1 || 2 < winner
    self.winner = winner
    ActiveRecord::Base.transaction do
      save!
      if level > 1
        match = Match.find_by(taikai_id: taikai_id, level: level - 1, index: ((index - 1) / 2) + 1)
        if match.defined_results?
          self.errors.add(:winner, :defined_results_for_target)
          raise ActiveRecord::Rollback
        end
        eval("match.assign_team#{index % 2 == 0 ? 2 : 1}(team#{winner})").save!
      end
      if level == 2
        # third place play-off
        match = Match.find_by(taikai_id: taikai_id, level: 1, index: 2)

        if match.defined_results?
          self.errors.add(:base, :defined_results_for_target)
          raise ActiveRecord::Rollback
        end
        eval("match.assign_team#{index % 2 == 0 ? 2 : 1}(team#{winner == 1 ? 2 : 1})").save!
      end
    end
  end

  def assign_team1(team)
    if self.team1
      self.team1.participants.each do |participant|
        participant.results.where(match_id: id).destroy_all
      end
    end
    self.team1 = team
    self.team1.participants.each do |participant|
      participant.create_empty_score_and_results id
    end

    self
  end

  def assign_team2(team)
    if self.team2
      self.team2.participants.each do |participant|
        participant.results.where(match_id: id).destroy_all
      end
    end
    self.team2 = team
    team2.participants.each do |participant|
      participant.create_empty_score_and_results id
    end

    self
  end

  def defined_results?
    results.where('status IS NOT NULL').any?
  end
end
