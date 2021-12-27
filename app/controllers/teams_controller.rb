class TeamsController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo

  def new
    @team = @participating_dojo.teams.build
  end

  def create
    @team = @participating_dojo.teams.build(team_params)
    @team.ensure_next_index

    if @team.save
      redirect_to controller: :participating_dojos, action: :edit, taikai_id: @taikai, id: @participating_dojo
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @team = @participating_dojo.teams.find(params[:id])
  end

  def update
    @team = @participating_dojo.teams.find(params[:id])
    @team.ensure_next_index

    if @team.update(team_params)
      redirect_to controller: 'participating_dojos', action: 'edit', taikai_id: @taikai, id: @participating_dojo
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team = @participating_dojo.teams.find(params[:id])

    @team.destroy!
    redirect_to controller: :participating_dojos, action: :edit, taikai_id: @taikai, id: @participating_dojo
  end

  private

  def team_params
    params
      .require(:team)
      .permit(
        :index
      )
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end
end
