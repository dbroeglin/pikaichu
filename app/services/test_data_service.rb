class TestDataService
  def self.generate_random_scores(taikai)
    raise "Taikai cannot be nil" if taikai.nil?
    raise "Cannot generate scores for 'matches'" if taikai.form_matches?

    if taikai.scoring_kinteki?
      taikai.participants.map(&:scores).flatten.map(&:results).flatten
            .each do |r|
        r.status = %w[hit miss].sample
        r.final = true
        r.save
      end
    elsif taikai.scoring_enteki?
      taikai.participants..map(&:scores).flatten.map(&:results).flatten
            .each do |r|
        r.value = [0, 3, 5, 7, 9, 10].sample
        r.status = r.value.zero? ? 'miss' : 'hit'
        r.final = true
        r.save
      end
    else
      raise "Unknown scoring method: #{taikai.scoring}"
    end
  end

  def self.finalize_scores(taikai)


    if taikai.form_matches?
      taikai.matches.each do |match|
        scope = Result.joins(score: { participant: { participating_dojo: :taikai } })
          .where("taikais.id = ?", taikai.id)
          .where("scores.match_id = ?", match.id)
        if taikai.scoring_kinteki?
          scope.each { |result| result.update(status: 'miss', final: true) }
        elsif taikai.scoring_enteki?
          scope.each { |result| result.update(status: 'miss', value: 0, final: true) }
        else
          raise "Unknown scoring method: #{taikai.scoring}"
        end
        end
    else
      scope = Result.joins(score: { participant: { participating_dojo: :taikai } }).where("taikais.id = ?", taikai.id)
      if taikai.scoring_kinteki?
        scope.each { |result| result.update(status: 'miss', final: true) }
      elsif taikai.scoring_enteki?
        scope.each { |result| result.update(status: 'miss', value: 0, final: true) }
      else
        raise "Unknown scoring method: #{taikai.scoring}"
      end
    end
  end
end
