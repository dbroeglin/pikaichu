class LeaderboardController < ApplicationController
  def show
    @taikai = Taikai.find(params[:id])
    @participants_by_score = {}

    if @taikai.individual?
      Participant.connection.select_all(%[
        SELECT participants.id, participants.firstname, participants.lastname, participants.index, participating_dojos.display_name, results.status, count(hits.id) as score
        FROM participants
          INNER JOIN participating_dojos
            ON participants.participating_dojo_id = participating_dojos.id
          INNER JOIN results
            ON results.participant_id = participants.id
          LEFT OUTER JOIN results as hits
            ON hits.participant_id = participants.id AND hits.status = 'hit'
        WHERE participating_dojos.taikai_id = $1
        GROUP BY participants.id, participants.firstname, participants.lastname, participants.index, participating_dojos.display_name, results.status, results.round, results.index
        ORDER BY score DESC, participating_dojos.display_name, participants.lastname, participants.firstname, results.round, results.index
        ], nil, [@taikai.id])
        .to_a
        .group_by do |hash|
          hash['id']
        end.each_pair do |id, lines|
          first_hash = lines[0]
          participant = Participant.new(first_hash.slice('firstname', 'lastname', 'index'))
          participant.results = lines.map do |hash|
            Result::new(hash.slice('round', 'index', 'status'))
          end
          participant.participating_dojo = ParticipatingDojo::new(first_hash.slice('display_name'))

          (@participants_by_score[first_hash['score']] ||= []) << participant
        end
    else
      @taikai = Taikai
        .includes(participating_dojos: {teams: [{participants: :results}]})
          .find(params[:id])

      @teams_by_score = @taikai.participating_dojos
        .map(&:teams).flatten
        .sort_by(&:score).reverse
        .group_by(&:score)
    end
  end
end
