class Leaderboard
  def initialize(taikai_id:, validated:)
    @taikai_id = taikai_id
    @validated = validated

    @taikai = Taikai.find(@taikai_id)
  end

  def compute_individual_leaderboard
    @taikai = Taikai
              .includes(participating_dojos: { participants: { scores: :results } })
              .find(@taikai_id)

    @participants_by_score = @taikai.participants.ranked(@validated)

    @score_by_participating_dojo = {}
    if @taikai.distributed?
      @taikai.participating_dojos.each do |participating_dojo|
        @score_by_participating_dojo[participating_dojo] =
          participating_dojo.participants.ranked(@validated)
      end
    end

    [@participants_by_score, @score_by_participating_dojo]
  end

  def compute_team_leaderboard
    @taikai = Taikai
              .includes(participating_dojos: { teams: [{ participants: { scores: :results } }] })
              .find(@taikai_id)

    unless @taikai.form_team? || @taikai.form_2in1?
      raise "compute_team_leaderboard works only for 'team' and '2in1' taikais"
    end

    @score_by_participating_dojo = {}

    @teams_by_score = @taikai.teams.ranked(@validated)

    if @taikai.distributed?
      @taikai.participating_dojos.each do |participating_dojo|
        @score_by_participating_dojo[participating_dojo] =
          participating_dojo.teams.ranked(@validated)
      end
    end
    [@teams_by_score, @score_by_participating_dojo]
  end

  def compute_matches_leaderboard
    @taikai = Taikai
              .includes(participating_dojos: { teams: [{ participants: { scores: :results } }] })
              .find(@taikai_id)

    raise "compute_matches_leaderboard works only 'matches' taikais" unless @taikai.form_matches?

    # TODO: refactor to taikai
    @teams_by_score = Match.where(taikai: @taikai, level: 1)
                           .order(index: :asc)
                           .map do |match|
                        match.ordered_teams.compact.map { |team| [team, match] }
                      end.flatten(1).compact
                           .map do |team, match|
      [team, match, team.score(match.id).score_value]
    end
    @matches = @taikai.matches
                      .group_by(&:level)
                      .each { |_, matches| matches.sort_by!(&:index) }

    [@teams_by_score, @matches]
  end

  def compute_intermediate_ranks
    if @taikai.form_individual?
      compute_individual_intermediate_ranks
    elsif @taikai.form_2in1?
      compute_individual_intermediate_ranks
      compute_team_intermediate_ranks
    elsif @taikai.form_team?
      compute_team_intermediate_ranks
    elsif @taikai.form_matches?
      compute_matches_intermediate_ranks
    else
      raise "Unknown taikai form: #{@taikai.form}"
    end
  end

  private

  def compute_individual_intermediate_ranks
    rank = 1
    participant_rank = 1
    participants_by_score, = compute_individual_leaderboard
    participants_by_score.each_pair do |_score, participants|
      participants.each_with_index do |participant, _index|
        participant.update(intermediate_rank: participant_rank, rank: participant_rank)
        rank += 1
      end
      participant_rank = rank
    end
  end

  def compute_team_intermediate_ranks
    rank = 1
    team_rank = 1
    teams_by_score, = compute_team_leaderboard

    teams_by_score.each_pair do |_score, teams|
      teams.each_with_index do |team, _team_index|
        team.update(intermediate_rank: team_rank, rank: team_rank)

        rank += 1
      end
      team_rank = rank
    end
  end

  def compute_matches_intermediate_ranks
    team_rank = 1
    teams_by_score, = compute_matches_leaderboard

    teams_by_score.each do |team, _match, _score|
      team.update(intermediate_rank: team_rank, rank: team_rank)

      team_rank += 1
    end
  end
end