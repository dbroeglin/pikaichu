class MarkingController < ApplicationController
  after_action :verify_authorized

  before_action do
    @page_title = "Marking"
  end

  def show
    @taikai = authorize(Taikai.find(params[:id]), :marking_show?)

    @match = nil

    @participating_dojos =
      marking_participating_dojos.includes(
        { participants: { scores: :results } },
        teams: [ participants: { scores: :results } ]
      )
  end

  def show_match
    @taikai = authorize(Taikai.find(params[:taikai_id]), :marking_show?)
    @match = @taikai.matches.find(params[:id])
  end

  def update
    # TODO: Optimize?
    @taikai = Taikai.includes(participating_dojos: { participants: { scores: :results } }).find(params[:id])

    authorize(@taikai, :marking_update?)

    @participating_dojos = @taikai.participating_dojos
    set_marking_records

    begin
      @result = @participant.add_result(@match&.id, params[:status], params[:value])
      @results = @score.results.round @result.round
      respond_to do |format|
        format.html { redirect_to action: :show, id: @taikai.id }
        format.turbo_stream
      end
    rescue Score::PreviousRoundNotValidatedError => e
      respond_to do |format|
        format.html { redirect_to action: :show, id: @taikai.id }
        format.turbo_stream do
          logger.warn "Participant #{@participant.id}'s previous round has not been validated yet"
          @results = @score.results.where(round: e.previous_round)
        end
      end
    rescue Score::UnableToFindUndefinedResultsError
      logger.warn "Participant #{@participant.id} has no undefined results left"
      render plain: "Unable to find non marked results", status: :unprocessable_entity
    end
  end

  def rotate
    @taikai = Taikai.find(params[:id])
    authorize(@taikai, :marking_update?)
    set_marking_records
    @result = @score.results.find(params[:result_id])

    if @taikai.scoring_kinteki?
      @result
        .rotate_status(@score.results.round(@result.round).count(&:marked?) == 4)
    else
      @result.rotate_value
    end

    @result.save!
    respond_to do |format|
      format.html { redirect_to action: :show, id: @taikai.id }
      format.turbo_stream do
        @results = @score.results.round @result.round
        render action: :update
      end
    end
  end

  def finalize
    @taikai = Taikai.find(params[:id])
    authorize(@taikai, :marking_update?)
    set_marking_records

    @participant.finalize_round(params[:round], @match&.id)
    respond_to do |format|
      format.html { redirect_to action: :show, id: @taikai.id }
      format.turbo_stream do
        @results = @score.results.round params[:round]
        render action: :update
      end
    end
  end

  private

  def taikai_params
    params.require(:taikai).permit(:participant_id, :status)
  end

  def marking_participating_dojos
    scope = @taikai.participating_dojos
    return scope if policy(@taikai).admin?

    scope
      .joins(staffs: :role)
      .where(
        'staffs.user_id': current_user.id,
        'role.code': TaikaiPolicy::MARKING_ROLES
      )
      .distinct
  end

  def set_marking_records
    @participant =
      @taikai
      .participants
      .where(
        participating_dojo_id:
          marking_participating_dojos.reorder(nil).select(:id)
      )
      .find(params[:participant_id])
    @match = @taikai.matches.find(params[:match_id]) if params[:match_id].present?
    @score = @participant.scores.find_by!(match_id: @match&.id)
  end
end
