class TieBreakController < ApplicationController
  def edit
    @taikai = authorize(Taikai.find(params[:id]), :tie_break_update?)

    @rankables = rankables
  end

  def update
    @taikai = authorize(Taikai.find(params[:id]), :tie_break_update?)

    params[:rank].each do |id, rank|
      @rankable = if params[:individual] == "true"
                    @taikai.participants.find(id)
      else
                    @taikai.teams.find(id)
      end

      next unless @rankable.rank != rank.to_i

      Taikai.transaction do
        @rankable.update!(rank: rank.to_i)
        TaikaiEvent.tie_break(taikai: @taikai, user: current_user, rankable: @rankable)
      end
    end

    redirect_to taikai_url @taikai
  rescue ActiveRecord::RecordInvalid
    @rankables = rankables
    render :edit, status: :unprocessable_entity
  end

  private

  def rankables
    if @taikai.form_individual?
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
end
