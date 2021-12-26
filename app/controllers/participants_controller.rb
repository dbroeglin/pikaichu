class ParticipantsController < ApplicationController
  before_action :set_taikai
  before_action :set_participating_dojo

  def new
    @participant = @participating_dojo.participants.build
  end

  def create
    @participant = @participating_dojo.participants.build(participant_params)

    if @participant.save
      redirect_to controller: 'participating_dojos', action: 'edit',
      taikai_id: @taikai, id: @participating_dojo
    else
      render :new
    end
  end

  def edit
    @participant = @participating_dojo.participants.find(params[:id])
  end

  def update
    @participant = @participating_dojo.participants.find(params[:id])

    if @participant.update(participant_params)
      redirect_to controller: 'participating_dojos', action: 'edit',
                  taikai_id: @taikai, id: @participating_dojo
    else
      render :edit
    end
  end

  def destroy
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
      )
  end

  def set_taikai
    @taikai = Taikai.find(params[:taikai_id])
  end

  def set_participating_dojo
    @participating_dojo = @taikai.participating_dojos.find(params[:participating_dojo_id])
  end
end
