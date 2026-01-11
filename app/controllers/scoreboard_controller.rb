class ScoreboardController < ApplicationController
  layout "public"

  allow_unauthenticated_access only: [ :show ]

  def show
    @scoreboard = Scoreboard.find_by!(api_key: params[:api_key])

    @previous_tachi = @scoreboard.participating_dojo.previous_tachi
    @current_tachi = @scoreboard.participating_dojo.current_tachi
    @taikai = @scoreboard.participating_dojo.taikai

    @display_tachi = if @previous_tachi && @previous_tachi.updated_at > @scoreboard.delay.seconds.ago
                       @previous_tachi
    else
                       @current_tachi
    end

    respond_to do |format|
      format.html do
      end
      format.json do
        render json: format_tachi(@display_tachi)
      end
    end
  end

  def format_tachi(tachi)
    data = {
      taikai: {
        name: @taikai.name,
        shortname: @taikai.shortname,
        form: @taikai.form,
        num_targets: @taikai.num_targets,
        num_arrows: @taikai.num_arrows,
        num_rounds: @taikai.num_rounds,
        scoring: @taikai.scoring,
        total_num_arrows: @taikai.total_num_arrows
      }
    }
    if tachi
      data.merge!(
        tachi: {
          index: tachi.index,
          round: tachi.round,
          participating_dojo: {
            name: @scoreboard.participating_dojo.display_name
          },
          participants: tachi.participants.map do |participant|
            score = participant.score(tachi.match_id)
            {
              name: participant.display_name,
              index: participant.index,
              score: if score
                       {
                         results: score.results.round(tachi.round).map do |result|
                           {
                             status: result.status,
                             value: result.value,
                             final: result.final
                           }
                         end
                       }
                     else
                       { results: [] }
                     end
            }
          end,
          updated_at: tachi.updated_at
        }
      )
    end
    data
  end
end
