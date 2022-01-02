class JudgingController < ApplicationController
  before_action do
    @page_title = "Judging"
  end

  def show
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])

    if @taikai.taikai_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
        .includes({participants: :results}, teams: [participants: :results])
        #.where('participants.id': 81)
    elsif @taikai.dojo_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
        .includes({participants: :results}, teams: [participants: :results])
        .joins(staffs: [:role])
        .where('staffs.user_id': current_user, 'role.code': :dojo_admin)
    else
      raise Pundit::NotAuthorizedError, "not allowed to show judging board for  #{@taikai.inspect}"
    end
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
    redirect_to action: 'show'#, only_participant_id: @participant.id
  end

  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end
end
