class JudgingController < ApplicationController
  def index
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])
    @participating_dojos = @taikai.participating_dojos
  end

  def update
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])
    @participating_dojos = @taikai.participating_dojos
    @participant = @taikai.participants.find(params[:participant_id])

    results = @participant.find_undefined_results
    if results.any?
      results.first.update!(status: params[:status])
      @participant.reload
    else
      flash.now[:alert] = "There is no more empty result to be set!" # TODO
    end
    redirect_to action: 'index'
  end

  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end
end
