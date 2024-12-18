class Match < ApplicationRecord
  audited

  belongs_to :taikai
  belongs_to :team1, class_name: "Team", optional: true
  belongs_to :team2, class_name: "Team", optional: true
  has_many :results, dependent: nil

  def team(index)
    raise ArgumentError, "index must be 1 or 2" unless [1, 2].include? index
    return team1 if index == 1

    team2
  end

  def set_team(index, team)
    raise ArgumentError, "index must be 1 or 2" unless [1, 2].include? index

    if index == 1
      self.team1 = team
    else
      self.team2 = team
    end
  end

  def score(index)
    team(index)&.scores&.find_by(match_id: id)
  end

  def winner?(index)
    winner == index
  end

  def assigned?
    team1 && team2
  end

  def finalized?
    results.where(final: false).none?
  end

  def decided?
    !winner.nil?
  end

  def ordered_teams
    if winner? 1
      [team1, team2]
    else
      [team2, team1]
    end
  end

  before_update do
    team1_change = changes[:team1_id]
    team2_change = changes[:team2_id]

    clean_team(team1_change.first) if team1_change&.first
    clean_team(team2_change.first) if team2_change&.first
    initialize_team(1) if team1_change&.second
    initialize_team(2) if team2_change&.second
  end

  before_commit do
    Tachi.find_by(match_id: id).update!(finished: true) if decided?
  end

  def select_winner(winner)
    raise "Winner can be only 1 or 2" if winner < 1 || winner > 2

    self.winner = winner
    ActiveRecord::Base.transaction do
      save!
      if level > 1

        match = Match.find_by(taikai_id: taikai_id, level: level - 1, index: ((index - 1) / 2) + 1)

        if match.defined_results?
          self.errors.add(:winner, :defined_results_for_target_match)
          raise ActiveRecord::Rollback
        end
        match.set_team(index.even? ? 2 : 1, team(winner))
        match.save!
      end
      if level == 2
        # third place play-off
        match = Match.find_by(taikai_id: taikai_id, level: 1, index: 2)

        if match.defined_results?
          self.errors.add(:base, :defined_results_for_target_match)
          raise ActiveRecord::Rollback
        end
        match.set_team(index.even? ? 2 : 1, team(winner == 1 ? 2 : 1))
        match.save!
      end
    end
  end

  def defined_results?
    results.where('status IS NOT NULL').any?
  end

  def to_ascii
    [
      "Match #{level}.#{index} (#{team1&.shortname} vs #{team2&.shortname}) [#{id}]",
      ("  Winner: #{winner} - #{team(winner)&.shortname}" if winner),
      (team1&.to_ascii(id) || "").gsub(/^/, "  "),
      (team2&.to_ascii(id) || "").gsub(/^/, "  "),
    ].flatten.compact.join("\n")
  end

  def build_empty_score_and_results
    initialize_team(1) if team(1)
    initialize_team(2) if team(2)

    self
  end

  private

  def clean_team(team_id)
    team = Team.find(team_id)
    score = team.score(id)
    if score.finalized?
      logger.error "Cannot clean team #{team_id} because score is finalized"
      errors.add(:base, :cant_change_teams_if_results_exist)
      throw :abort
    end
    team.score(id).destroy!
    team.participants.each do |participant|
      participant.scores.find_by(match_id: id).destroy!
    end
  end

  def initialize_team(index)
    t = team(index)
    t.build_empty_score match_id: id
    t.participants.each do |participant|
      participant.build_empty_score_and_results id
    end

    t.save!
  end
end
