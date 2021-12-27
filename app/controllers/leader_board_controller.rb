class LeaderBoardController < ApplicationController
  #before_action :authenticate_user!

  def index
    @taikai = Taikai.find(params[:id])
    @results = {}
    Participant.connection.select_all(%[
      SELECT "participants".*, count(results.id) as score
      FROM "participants"
        INNER JOIN "participating_dojos"
          ON "participants"."participating_dojo_id" = "participating_dojos"."id"
        LEFT OUTER JOIN results
          ON results.participant_id = participants.id AND results.status = 'hit'
      WHERE "participating_dojos"."taikai_id" = $1 GROUP BY participants.id
      ORDER BY score DESC, participants.lastname, participants.firstname], nil, [@taikai.id]).to_a.map do |hash|
        score = hash.delete 'score'
        (@results[score] ||= []) << Participant.new(hash)
      end
  end
end
