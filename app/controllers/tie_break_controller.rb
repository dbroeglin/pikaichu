class TieBreakController < ApplicationController

  def index
    @taikai = authorize(Taikai.find(params[:taikai_id]), :tie_break_update?)

    @rankables = if @taikai.form_individual?
      @individual = "true"
      @taikai.participants.intermediate_ranked
    elsif @taikai.form_2in1?
      if params[:individual] == "true"
        @individual = "true"
        @taikai.participants.intermediate_ranked
      else
        @individual = "false"
        @taikai.teams.intermediate_ranked
      end
    elsif @taikai.form_team?
      @individual = "false"
      @taikai.teams.ranked
    elsif @taikai.form_matches?
      @teams_by_score, @matches = leaderboard.compute_matches_leaderboard
    else
      raise "Unknown taikai form: #{@taikai.form}"
    end
  end

  def update
    @taikai = authorize(Taikai.find(params[:taikai_id]), :tie_break_update?)
    if params[:individual] == "true"
      @rankable = Participant.find(params[:id])
    else
      @rankable = Team.find(params[:id])
    end

    @rankable.update(rank: params[:rank])

    redirect_to action: :index, params: { individual: params[:individual] }
  end

end
