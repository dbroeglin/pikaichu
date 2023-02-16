class RectificationController < ApplicationController

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

    if @taikai.scoring_enteki?
      @result.override_value(params[:result][:value])
    else
      @result.override_status(params[:result][:status])
    end

    if @result.save
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
