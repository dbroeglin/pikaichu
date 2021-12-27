class ParticipantsController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo
  before_action :set_team
  before_action :set_parent_association

  def new
    @participant = @parent_association.build
  end

  def create
    @participant = @parent_association.build(participant_params)
    @participant.participating_dojo = @participating_dojo if @team

    if @participant.save && @participant.generate_empty_results
      redirect_to_edit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @participant = @parent_association.find(params[:id])
  end

  def update
    @participant = @parent_association.find(params[:id])

    if @participant.update(participant_params)
      redirect_to_edit
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @participant = @parent_association.find(params[:id])

    @participant.destroy
    redirect_to_edit
  end

  private

  def participant_params
    params
      .require(:participant)
      .permit(
        :taikai_id,
        :participating_dojo_id,
        :team_id,
        :firstname,
        :lastname,
      )
  end

  def redirect_to_edit
    if @team
      redirect_to controller: 'teams', action: 'edit',
                  taikai_id: @taikai, participating_dojo: @participating_dojo, id: @team
    else
      redirect_to controller: 'participating_dojos', action: 'edit',
                  taikai_id: @taikai, id: @participating_dojo
    end
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end

  def set_team
    if params[:team_id]
      @team = @participating_dojo.teams.find(params[:team_id])
    end
  end

  def set_parent_association
    @parent_association = @team ? @team.participants : @participating_dojo.participants
  end
end
