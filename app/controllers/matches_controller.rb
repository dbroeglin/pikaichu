class MatchesController < ApplicationController
  before_action :set_taikai

  def index
    @matches = @taikai.matches
      .group_by(&:level)
      .each { |_, matches| matches.sort_by!(&:index) }
  end

  def edit
    @match = @taikai.matches.find(params[:id])
    @teams = @taikai
      .participating_dojos.map(&:teams).flatten
      .sort_by(&:shortname)
  end

  def update
    @match = Match.find(params[:id])
    @match.update(match_params)

    if @match.errors.any?
      @teams = @taikai
        .participating_dojos.map(&:teams).flatten
        .sort_by(&:shortname)
      render :edit, status: :unprocessable_entity
      return
    end

    if @match.update(match_params)
      redirect_to action: 'index'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def select_winner
    @match = @taikai.matches.find(params[:id])

    @match.select_winner(@match.score(1) > @match.score(2) ? 1 : 2)

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
