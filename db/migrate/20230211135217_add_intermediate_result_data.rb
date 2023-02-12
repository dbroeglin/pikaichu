class AddIntermediateResultData < ActiveRecord::Migration[7.0]
  def change
    add_column :scores, :intermediate_hits, :integer, default: 0
    add_column :scores, :intermediate_value, :integer, default: 0

    Score.connection.schema_cache.clear!
    Score.reset_column_information

    Taikai.where(form: ['2in1', 'team']).each do |taikai|
      puts "Migration #{taikai.shortname}..."
      taikai.teams.each do |team|
        if team.score.nil?
          puts "  Creating score for team #{team.id} - #{team.shortname}..."
          score = team.create_empty_score
          puts "     Created: #{score&.id}"
        end
      end
    end

    Taikai.where(form: ['matches']).each do |taikai|
      puts "Matches migration #{taikai.shortname}..."
      taikai.matches.each do |match|
        if match.team1 && match.score(1).nil?
          puts "Creating score for team1 (#{match.team1.id}) #{match.team1.shortname}..."
          match.team1.create_empty_score(match_id: match.id)

        end
        if match.team2 && match.score(2).nil?

          puts "Creating score for team2 (#{match.team2.id}) #{match.team2.shortname}..."
          match.team2.create_empty_score(match_id: match.id)
        end
      end
    end

    failed = false
    Participant.all.each do |participant|
      participant.scores.each do |score|
        score.recalculate_individual_score
      rescue
        failed = true
        puts "Failed for score  #{score.id} - #{score.participant.participating_dojo.taikai.shortname}"
        p score
      end
    end

    raise "failed" if failed
  end
end
