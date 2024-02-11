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

    Taikai.transaction do
      @match.assign_attributes(match_params)
      changed_winner = @match.changes[:winner]
      @match.save!
      @match.select_winner(@match.winner) if changed_winner
    end

    redirect_to action: 'index'
  rescue ActiveRecord::RecordInvalid
    @teams = @taikai
             .participating_dojos.map(&:teams).flatten
             .sort_by(&:shortname)
    render :edit, status: :unprocessable_entity
  end

  def select_winner
    @match = @taikai.matches.find(params[:id])

    @match.select_winner(@match.score(1).score_value > @match.score(2).score_value ? 1 : 2)

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
