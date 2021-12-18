class ResultsController < ApplicationController

  private

  def result_params
    params
      .require(:result)
      .permit(
        :round,
        :arrow_nb,
        :status
      )
  end
end
