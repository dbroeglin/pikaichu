class MarkingController < ApplicationController
  before_action do
    @page_title = "Marking"
  end

  def show
    @taikai = Taikai.includes(participating_dojos: { participants: [ { scores: :results }] }).find(params[:id])
    @match = nil

    if current_user.admin? || @taikai.taikai_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
                                    .includes({ participants: { scores: :results }}, teams: [participants: { scores: :results }])
    elsif @taikai.dojo_admin?(current_user)
      @participating_dojos = @taikai.participating_dojos
                                    .includes({ participants: { scores: :results }}, teams: [participants: { scores: :results }])
                                    .joins(staffs: [:role])
                                    .where('staffs.user_id': current_user, 'role.code': :dojo_admin)
    else
      raise Pundit::NotAuthorizedError, "not allowed to show marking board for  #{@taikai.inspect}"
    end
  end

  def show_match
    @taikai = Taikai.find(params[:taikai_id])
    @match = @taikai.matches.find(params[:id])
  end


  def update
    # TODO: Optimize?
    @taikai = Taikai.includes(participating_dojos: { participants: { scores: :results }}).find(params[:id])
    @participating_dojos = @taikai.participating_dojos
    @participant = @taikai.participants.find(params[:participant_id])
    @match = Match.find_by(id: params[:match_id])

    begin
      @result = @participant.add_result(@match&.id, params[:status], params[:value])
      @results = @participant.scores.find_by(match_id: @match&.id).results.round @result.round
    rescue Score::PreviousRoundNotValidatedError => e
      respond_to do |format|
        format.html { redirect_to action: :show, id: @taikai.id }
        format.turbo_stream do
          logger.warn"Participant #{@participant.id}'s previous round has not been validated yet"
          @results = @participant.results.where(match_id: @match&.id, round: e.previous_round)
          raise "debug!!!"
        end
      end
    rescue Score::UnableToFindUndefinedResultsError
      logger.warn "Participant #{@participant.id} has no undefined results left"
      render plain: "Unable to find non marked results", status: :unprocessable_entity
    end
  end

  def rotate
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @result = @participant.scores.find_by(match_id: params[:match_id]).results.find(params[:result_id])
    @match = Match.find_by(id: params[:match_id])

    if @taikai.scoring_kinteki?
      @result.rotate_status(@participant.scores.find_by(match_id: @match&.id).results.round(@result.round).count(&:marked?) == 4)
    else
      @result.rotate_value
    end

    @result.save!
    respond_to do |format|
      format.turbo_stream do
        @results = @participant.scores.find_by(match_id: @match&.id).results.round @result.round
        render action: :update
      end
    end
  end

  def finalize
    @taikai = Taikai.find(params[:id])
    @participant = @taikai.participants.find(params[:participant_id])
    @results = @participant.scores.find_by(match_id: params[:match_id]).results.round params[:round]
    @match = Match.find_by(id: params[:match_id])

    @results.update_all(final: true)
    respond_to do |format|
      format.turbo_stream do
        @results = @participant.scores.find_by(match_id: params[:match_id]).results.round params[:round]
        render action: :update
      end
    end
  end

  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end
end
