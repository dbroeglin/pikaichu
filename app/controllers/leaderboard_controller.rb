class LeaderboardController < ApplicationController
  def show
    @final = false
    compute_leaderboard(@final)
  end

  def public
    @final = true
    compute_leaderboard(@final)
  end

  private

  def compute_leaderboard(final)
    @taikai = Taikai.find(params[:id])

    if @taikai.individual?
      @taikai = Taikai
                .includes(participating_dojos: { participants: :results })
                .find(params[:id])

      @participants_by_score = @taikai.participating_dojos
                                      .map(&:participants).flatten
                                      .sort_by { |participant| participant.score(final) }.reverse
                                      .group_by { |participant| participant.score(final) }
                                      .each { |_, participants| participants.sort_by!(&:index) }
    else
      @taikai = Taikai
                .includes(participating_dojos: { teams: [{ participants: :results }] })
                .find(params[:id])

      @teams_by_score = @taikai.participating_dojos
                               .map(&:teams).flatten
                               .sort_by { |participant| participant.score(final) }.reverse
                               .group_by { |participant| participant.score(final) }
                               .each { |_, participants| participants.sort_by!(&:index) }
    end
  end
end
