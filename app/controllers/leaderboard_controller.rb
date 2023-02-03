class LeaderboardController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:public]

  def show
    @taikai = Taikai.find(params[:id])

    leaderboard = Leaderboard.new(taikai_id: @taikai.id, validated: false)
    if @taikai.form_individual? || @taikai.form_2in1?
      @participants_by_score, @score_by_participating_dojo = leaderboard.compute_individual_leaderboard
    elsif @taikai.form_team?
      @teams_by_score, @score_by_participating_dojo = leaderboard.compute_team_leaderboard
    elsif @taikai.form_matches?
      @teams_by_score, @matches = leaderboard.compute_matches_leaderboard
    else
      raise "Unknown taikai form: #{@taikai.form}"
    end
  end

  def show_2in1
    @taikai = Taikai.find(params[:id])
    leaderboard = Leaderboard.new(taikai_id: @taikai.id, validated: false)

    @teams_by_score, @score_by_participating_dojo = leaderboard.compute_team_leaderboard
  end

  def public
    @taikai = Taikai.find(params[:id])
    leaderboard = Leaderboard.new(taikai_id: @taikai.id, validated: true)

    if @taikai.form_2in1?
      if params[:individual]
        @participants_by_score, @score_by_participating_dojo = leaderboard.compute_individual_leaderboard
      else
        @teams_by_score, @score_by_participating_dojo = leaderboard.compute_team_leaderboard
      end
    elsif @taikai.form_individual?
      @participants_by_score, @score_by_participating_dojo = leaderboard.compute_individual_leaderboard
    elsif @taikai.form_team?
      @teams_by_score, @score_by_participating_dojo = leaderboard.compute_team_leaderboard
    else
      raise "Unknown taikai form: #{@taikai.form}"
    end

    render layout: 'public'
  end

  private
end
