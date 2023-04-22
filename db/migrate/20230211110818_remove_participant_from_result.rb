class RemoveParticipantFromResult < ActiveRecord::Migration[7.0]
  def up
    Result.all.each do |result|
      if result.participant_id != result.score.participant_id
        raise "Error with #{result.score} AND #{result.score.inspect}"
      end
      raise "Nil #{result.inspect}" if result.participant_id.nil?

      nil
    end

    remove_column :results, :participant_id
  end
end
