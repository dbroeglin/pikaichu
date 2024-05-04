class LeaderboardController < ApplicationController
  layout 'taikai'

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
    build_taikai_data()

    render layout: 'public'
  end

  def ajax_public
    build_taikai_data()

    leaderboard_data = { 'num_rounds': @taikai.num_rounds, 'num_arrows': @taikai.num_arrows, 'ranks' => [] }
    rank_participants = nil

    rank = 0
    @participants_by_score.each_pair do |score, participants|
      participants.each_with_index do |participant, index|
        rank += 1

        if index == 0
          rank_participants = { 'score' => participant.score, 'participants' => [] }
        end

        participant_data = {
          'dojo' => @taikai.distributed? ? participant.participating_dojo.display_name : participant.club,
          'name' => participant.display_name,
          'results' => []
        }
        participant.score.results.each do |result|
          participant_data['results'] << result.status
        end
        rank_participants['participants'] << participant_data

        if index == 0
          leaderboard_data['ranks'] << rank_participants
        end
      end
    end

    render json: leaderboard_data
  end

  private def build_taikai_data
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
    elsif @taikai.form_matches?
      @teams_by_score, @matches = leaderboard.compute_matches_leaderboard
    else
      raise "Unknown taikai form: #{@taikai.form}"
    end
  end
end
