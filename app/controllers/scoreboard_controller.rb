class ScoreboardController < ApplicationController
  layout 'public'

  skip_before_action :authenticate_user!, :only => [:show]

  def show
    @scoreboard = Scoreboard.find_by!(api_key: params[:api_key])

    @tachi = @scoreboard.participating_dojo.current_tachi

    # answer different formats
    respond_to do |format|
      format.html do
        @taikai = @scoreboard.participating_dojo.taikai
      end
      format.json do
        taikai = @scoreboard.participating_dojo.taikai

        render json: {
          index: @tachi.index,
          round: @tachi.round,
          taikai: {
            name: taikai.name,
            shortname: taikai.shortname,
            form: taikai.form,
            num_targets: taikai.num_targets,
            num_arrows: taikai.num_arrows,
            num_rounds: taikai.num_rounds,
            scoring: taikai.scoring,
            total_num_arrows: taikai.total_num_arrows
          },
          participating_dojo: {
            name: @scoreboard.participating_dojo.display_name,
          },
          results: [
            @tachi.participants.map do |participant|
              score = participant.scores.first
              {
                name: participant.display_name,
                index: participant.index,
                score: {
                  results: score.results.round(@tachi.round).map do |result|
                    {
                      status: result.status,
                      value: result.value,
                      final: result.final
                    }
                  end
                },
                team: {
                  shortname: participant.team.shortname,
                  index: participant.team.index
                },
              }
            end
          ]
        }
      end
    end
  end
end
