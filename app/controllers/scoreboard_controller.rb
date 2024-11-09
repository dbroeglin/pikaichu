class ScoreboardController < ApplicationController
  layout 'public'

  skip_before_action :authenticate_user!, :only => [:show]

  def show
    @scoreboard = Scoreboard.find_by!(api_key: params[:api_key])

    @scores = @tachi.current_results

    # answer different formats
    respond_to do |format|
      format.html do
        render plain: @scores
      end
      format.json do
        render json: @scores.to_json
      end
    end
  end
end
