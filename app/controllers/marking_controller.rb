class MarkingController < ApplicationController
  before_action do
    @page_title = "Marking"
  end

  def show
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])

    if @taikai.taikai_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
        .includes({participants: :results}, teams: [participants: :results])
    elsif @taikai.dojo_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
        .includes({participants: :results}, teams: [participants: :results])
        .joins(staffs: [:role])
        .where('staffs.user_id': current_user, 'role.code': :dojo_admin)
    else
      raise Pundit::NotAuthorizedError, "not allowed to show marking board for  #{@taikai.inspect}"
    end
  end

  def update # TODO: Optimize?
    @taikai = Taikai.includes(participating_dojos: { participants: [ :results ]}).find(params[:id])
    @participating_dojos = @taikai.participating_dojos
    @participant = @taikai.participants.find(params[:participant_id])

    results = @participant.find_undefined_results
    if results.any?
      @result = results.first
      @result.update!(status: params[:status])
    else
      flash.now[:alert] = "There is no more empty result to be set!" # TODO
    end
    respond_to do |format|
      format.html { redirect_to action: :show }
      format.turbo_stream {
        @results = @participant.results.round @result.round
      }
    end
  end

  def rotate
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @result = @participant.results.find(params[:result_id])

    @result.status = case @result.status
    when 'hit' then 'miss'
    when 'miss' then 'hit'
    when 'unknown' then 'hit'
    else raise "Cannot change value of a result that has not been marked yet"
    end
    @result.save!
    respond_to do |format|
      format.turbo_stream {
        @results = @participant.results.round @result.round
        render action: :update
      }
    end
  end

  def finalize
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @results = @participant.results.round(params[:round])

    @results.update_all(final: true)
    respond_to do |format|
      format.turbo_stream {
        @results = @participant.results.round params[:round]
        render action: :update
      }
    end
  end


  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end
end
