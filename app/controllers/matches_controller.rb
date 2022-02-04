class MatchesController < ApplicationController
  before_action :set_taikai

  def index
    @matches = @taikai.matches
      .group_by(&:level)
      .each { |_, matches| matches.sort_by!(&:index) }
  end

  def edit
    @match = @taikai.matches.find(params[:id])

  end

  def update
    @match = Match.find(params[:id])

    @match.assign_attributes(match_params)

    if @match.changes[:team1_id]
      @match.assign_team1(match.team1)
    elsif @match.changes[:team2_id]
      @match.assign_team2(match.team2)
    end
    if @match.changes[:winner]
      @match.select_winner(@match.winner)
    end

    if @match.update(match_params)
      redirect_to action: 'index'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def select_winner
    @match = @taikai.matches.find(params[:id])

   @match.select_winner(@match.score1 > @match.score2 ? 1 : 2)

   redirect_to action: 'index', status: :see_other
  end

  private

  def match_params
    params
      .require(:match)
      .permit(
        :winner,
        :team1_id,
        :team2_id,
      )
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end
end
