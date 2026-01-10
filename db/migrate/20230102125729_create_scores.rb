class CreateScores < ActiveRecord::Migration[7.0]
  def up
    create_table :scores do |t|
      t.references :participant, null: true, foreign_key: true

      t.references :team, null: true, foreign_key: true
      t.references :match, null: true, foreign_key: true

      t.integer :hits, default: 0
      t.integer :value, default: 0

      t.timestamps
    end

    add_index :scores, [ :team_id, :match_id ], unique: true, name: "by_team_id_match_id"
    add_index :scores, [ :participant_id, :match_id ], unique: true, name: "by_participant_id"

    add_reference :results, :score, null: true, foreign_key: true

    Result.all.where(round_type: :normal)
          .group_by { |result| [ result.participant_id, result.match_id ] }
          .each do |key, group|
      participant_id, match_id = key
      score = Participant.find(participant_id).score(true, match_id)
      new_score = Score.create!(
        participant_id: participant_id,
        match_id: match_id,
        hits: score&.hits || 0,
        value: score&.value || 0
      )
      Result.where(id: group).update_all(score_id: new_score.id)
    end

    Team.joins(participating_dojo: :taikai).where("taikais.form <> 'matches'").each do |team|
      score = team.score(true)
      Score.create!(
        team_id: team.id,
        hits: score&.hits || 0,
        value: score&.value || 0
      )
    end

    Match.all.each do |match|
      score1 = match.score1(true)
      score2 = match.score2(true)
      if match.team1_id
        Score.create!(
          team_id: match.team1_id,
          match_id: match.id,
          hits: score1&.hits || 0,
          value: score1&.value || 0
        )
      end
      next unless match.team2_id

      Score.create!(
        team_id: match.team2_id,
        match_id: match.id,
        hits: score2&.hits || 0,
        value: score2&.value || 0
      )
    end

    # migration sanity checks

    score_count = 0
    Participant.all.each do |participant|
      participant.scores.each do |score|
        score_count += 1
        raise "error on #{participant.inspect}" if participant.score(true, score.match_id) != score
      end
    end

    Team.all.each do |team|
      team.scores.each do |score|
        score_count += 1
        raise "error on #{team.inspect}" if team.score(true, score.match_id) != score
      end
    end

    raise "Not all scores where checked #{score_count} != #{Score.count}" if score_count != Score.count

    Result.where(round_type: 'tie_break').delete_all

    change_column_null :results, :score_id, false
  end

  def down
    remove_reference :results, :score
    drop_table :scores
  end
end
