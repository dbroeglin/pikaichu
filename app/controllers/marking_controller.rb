class MarkingController < ApplicationController
  before_action do
    @page_title = "Marking"
  end

  def show
    @taikai = Taikai.includes(participating_dojos: { participants: [:results] }).find(params[:id])

    if current_user.admin? || @taikai.taikai_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
                                    .includes({ participants: :results }, teams: [participants: :results])
    elsif @taikai.dojo_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
                                    .includes({ participants: :results }, teams: [participants: :results])
                                    .joins(staffs: [:role])
                                    .where('staffs.user_id': current_user, 'role.code': :dojo_admin)
    else
      raise Pundit::NotAuthorizedError, "not allowed to show marking board for  #{@taikai.inspect}"
    end
  end

  def update
    # TODO: Optimize?
    @taikai = Taikai.includes(participating_dojos: { participants: [:results] }).find(params[:id])
    @participating_dojos = @taikai.participating_dojos
    @participant = @taikai.participants.find(params[:participant_id])

    @result = @participant.results.first_empty
    if @result
      if @participant.previous_round_finalized?(@result)
        @result.update!(status: params[:status])
        respond_to do |format|
          format.html { redirect_to action: :show }
          format.turbo_stream do
            @results = @participant.results.round @result.round
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to action: :show }
          format.turbo_stream do
            @results = @participant.results.round(@result.round - 1)
          end
        end
      end
    else
      render plain: "Unable to find undefined results", status: :unprocessable_entity
    end
  end

  def rotate
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @result = @participant.results.find(params[:result_id])

    num_marked_results_in_round = @participant.results.round(@result.round).count(&:marked?)

    @result.status = case @result.status
                     when 'hit' then 'miss'
                     when 'miss' then num_marked_results_in_round == 4 ? 'hit' : 'unknown'
                     when 'unknown' then 'hit'
                     else raise "Cannot change value of a result that has not been marked yet"
                     end
    @result.save!
    respond_to do |format|
      format.turbo_stream do
        @results = @participant.results.round @result.round
        render action: :update
      end
    end
  end

  def finalize
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @results = @participant.results.round(params[:round])

    @results.update_all(final: true)
    respond_to do |format|
      format.turbo_stream do
        @results = @participant.results.round params[:round]
        render action: :update
      end
    end
  end

  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end
end
