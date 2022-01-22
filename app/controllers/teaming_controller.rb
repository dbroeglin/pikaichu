class TeamingController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo

  def edit
    @teams = @participating_dojo.teams.includes(:participants).order("teams.shortname ASC")
  end

  def clear
    @participating_dojo.participants.update_all(team_id: nil)

    redirect_to action: :edit, status: 303
  end

  def apply
    @teams = @participating_dojo.teams.includes(:participants).order("teams.shortname ASC")

    @participating_dojo.participants.group_by(&:club)
      .each_slice()

    redirect_to action: :edit, status: 303
  end

  private

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:id])
  end
end
