class RectificationController < ApplicationController
  layout 'taikai'

  def index
    @taikai = authorize Taikai.find(params[:taikai_id]), :rectification_update?
  end

  def edit
    @taikai = authorize Taikai.find(params[:taikai_id]), :rectification_update?
    @result = Result.joins(score: { participant: {participating_dojo: :taikai}}).where("taikai.id": @taikai.id).find(params[:id])
  end

  def update
    @taikai = authorize Taikai.find(params[:taikai_id]), :rectification_update?
    @result = Result.joins(score: { participant: {participating_dojo: :taikai}}).where("taikai.id": @taikai.id).find(params[:id])

    previous_status = @result.status
    previous_value = @result.value

    changed = if @taikai.scoring_enteki?
      @result.override_value(params[:result][:value])
    else
      @result.override_status(params[:result][:status])
    end

    ok = true
    if changed
      Result.transaction do
        ok = @result.save
        TaikaiEvent.rectification(
          taikai: @taikai,
          user: current_user,
          result: @result,
          previous_status: previous_status,
          previous_value: previous_value
        )
      end
    end

    if ok
      redirect_to action: :index, params: { taikai_id: @taikai.id }
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def result_params
    params
      .require(:result)
      .permit(
        :value,
        :status,
      )
  end
end
