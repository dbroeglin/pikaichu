class LeaderboardController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:public]

  def show
    @taikai = Taikai.find(params[:id])
    @final = false
    @num_tie_break_arrows = 0

    if @taikai.form_individual? || @taikai.form_2in1?
      compute_individual_leaderboard(@final)
    else
      compute_team_leaderboard(@final)
    end
  end

  def show_2in1
    @taikai = Taikai.find(params[:id])
    @final = false

    @num_tie_break_arrows = 0
    compute_team_leaderboard(@final)
  end

  def public
    @taikai = Taikai.find(params[:id])
    @final = true

    @num_tie_break_arrows = 0
    if @taikai.form_individual? || @taikai.form_2in1?
      if params[:individual]
        compute_individual_leaderboard(@final)
      else
        compute_team_leaderboard(@final)
      end
    elsif @taikai.form_individual?
      compute_individual_leaderboard(@final)
    else
      compute_team_leaderboard(@final)
    end

    render layout: 'public'
  end

  private

  def compute_individual_leaderboard(final)
    @taikai = Taikai
      .includes(participating_dojos: { participants: :results })
      .find(params[:id])

    @num_tie_break_arrows = 0
    @participants_by_score = @taikai.participating_dojos
      .map(&:participants).flatten
      .sort_by { |participant| participant.score(final) }.reverse
      .group_by { |participant| participant.score(final) }
      .each { |_, participants| participants.sort_by!(&:index) }

    @score_by_participating_dojo = {}
    if @taikai.distributed?
      @taikai.participating_dojos.each do |participating_dojo|
        @score_by_participating_dojo[participating_dojo] =
          participating_dojo.participants
            .sort_by { |participant| participant.score(final) }.reverse
            .group_by { |participant| participant.score(final) }
            .each { |_, participants| participants.sort_by!(&:index) }
      end
    end
  end

  def compute_team_leaderboard(final)
    @taikai = Taikai
      .includes(participating_dojos: { teams: [{ participants: :results }] })
      .find(params[:id])

    @num_tie_break_arrows = 0
    @score_by_participating_dojo = {}

    if @taikai.form_team? || @taikai.form_2in1?
      @num_tie_break_arrows = Result.joins(participant: :participating_dojo)
        .where("participating_dojo.taikai_id": @taikai, round_type: 'tie_break')
        .maximum(:index) || 0
      @teams_by_score = @taikai.teams_by_score(final)

      if @taikai.distributed?
        @taikai.participating_dojos.each do |participating_dojo|
          @score_by_participating_dojo[participating_dojo] =
            participating_dojo.teams_by_score(final)
        end
      end
    elsif @taikai.form_matches?
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
      else
      raise "compute_team_leaderboard works only for 'team', '2in1' and 'matches' taikais"
    end
  end

end
