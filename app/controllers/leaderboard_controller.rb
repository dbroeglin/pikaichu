class LeaderboardController < ApplicationController
  def show
    @taikai = Taikai.find(params[:id])
    @final = false

    if @taikai.form_individual? || @taikai.form_2in1?
      compute_individual_leaderboard(@final)
    else
      compute_team_leaderboard(@final)
    end
  end

  def show_2in1
    @taikai = Taikai.find(params[:id])
    @final = false

    compute_team_leaderboard(@final)
  end

  def public
    @taikai = Taikai.find(params[:id])
    @final = true

    if @taikai.form_individual? || @taikai.form_2in1?
      compute_individual_leaderboard(@final)
    else
      compute_team_leaderboard(@final)
    end
  end

  private

  def compute_leaderboard(final)
  end

  def compute_individual_leaderboard(final)
    @taikai = Taikai
      .includes(participating_dojos: { participants: :results })
      .find(params[:id])

    @participants_by_score = @taikai.participating_dojos
      .map(&:participants).flatten
      .sort_by { |participant| participant.score(final) }.reverse
      .group_by { |participant| participant.score(final) }
      .each { |_, participants| participants.sort_by!(&:index) }

  end

  def compute_team_leaderboard(final)
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
