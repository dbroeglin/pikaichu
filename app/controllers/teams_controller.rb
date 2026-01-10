class TeamsController < ApplicationController
  layout "taikai"

  before_action :set_taikai
  before_action :set_participating_dojo

  def new
    @team = @participating_dojo.teams.build
  end

  def edit
    @team = @participating_dojo.teams.find(params[:id])
  end

  def create
    @team = @participating_dojo.teams.build(team_params)

    if @team.save
      redirect_to controller: :participating_dojos, action: :edit, taikai_id: @taikai, id: @participating_dojo
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @team = @participating_dojo.teams.find(params[:id])

    if @team.update(team_params)
      redirect_to controller: "participating_dojos", action: "edit", taikai_id: @taikai, id: @participating_dojo
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team = @participating_dojo.teams.find(params[:id])

    @team.destroy!
    redirect_to controller: :participating_dojos,
                action: :edit,
                taikai_id: @taikai,
                id: @participating_dojo,
                status: :see_other
  end

  private

  def team_params
    params
      .require(:team)
      .permit(
        :index,
        :shortname,
        :mixed
      )
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end
end
