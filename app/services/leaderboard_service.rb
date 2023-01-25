class LeaderboardService
  def initialize(taikai_id: , validated: )
    @taikai_id = taikai_id
    @validated = validated
  end

  def compute_individual_leaderboard
    @taikai = Taikai
      .includes(participating_dojos: { participants: { scores: :results }})
      .find(@taikai_id)

    @participants_by_score = @taikai.participants_by_score(@validated)

    @score_by_participating_dojo = {}
    if @taikai.distributed?
      @taikai.participating_dojos.each do |participating_dojo|
        @score_by_participating_dojo[participating_dojo] =
          participating_dojo.participants
            .sort_by { |participant| participant.score(@inal) }.reverse
            .group_by { |participant| participant.score(@validated) }
            .each { |_, participants| participants.sort_by!(&:index) }
      end
    end

    return @participants_by_score, @score_by_participating_dojo
  end

  def compute_team_leaderboard
    @taikai = Taikai
      .includes(participating_dojos: { teams: [{ participants: { scores: :results }}] })
      .find(@taikai_id)

    unless @taikai.form_team? || @taikai.form_2in1?
      raise "compute_team_leaderboard works only for 'team' and '2in1' taikais"
    end

    @score_by_participating_dojo = {}

    @teams_by_score = @taikai.teams_by_score(@validated)

    if @taikai.distributed?
      @taikai.participating_dojos.each do |participating_dojo|
        @score_by_participating_dojo[participating_dojo] =
          participating_dojo.teams_by_score(@validated)
      end
    end
    return @teams_by_score, @score_by_participating_dojo
  end

  def compute_matches_leaderboard
    @taikai = Taikai
      .includes(participating_dojos: { teams: [{ participants: { scores: :results }}] })
      .find(@taikai_id)

    unless @taikai.form_matches?
      raise "compute_matches_leaderboard works only 'matches' taikais"
    end

    @teams_by_score = Match.where(taikai: @taikai, level: 1)
      .order(index: :asc)
      .map do |match|
        match.ordered_teams.compact.map { |team| [team, match] }
      end.flatten(1).compact
      .map do |team, match|
        [team, match, team.score(true, match.id)]
      end
    @matches = @taikai.matches
      .group_by(&:level)
      .each { |_, matches| matches.sort_by!(&:index) }

    return @teams_by_score, @matches
  end


end