class ParticipantsController < ApplicationController
  def edit
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
    @participant = @participating_dojo.participants.find(params[:id])
  end

  def update
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
    @participant = @participating_dojo.participants.find(params[:id])

    if @participant.update(participant_params)
      redirect_to controller: 'participating_dojos', action: 'edit',
                  taikai_id: @taikai, id: @participating_dojo
    else
      render :edit
    end
  end

  def destroy
    @taikai = Taikai.find(params[:taikai_id])
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
    @participant = @participating_dojo.participants.find(params[:id])

    @participant.destroy
    redirect_to controller: 'participating_dojos', action: 'edit',
    taikai_id: @taikai, id: @participating_dojo
end

  private

  def participant_params
    params
      .require(:participant)
      .permit(
        :taikai_id,
        :participating_dojo_id,
        :firstname,
        :lastname,
        :title,
        :level,
      )
  end
end
