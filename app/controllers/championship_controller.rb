class ChampionshipController < ApplicationController
  def export
    @taikais = Taikai
      .joins(:taikai_transitions)
      .order(:scoring, :start_date)
      .where("taikai_transitions.most_recent = true")
      .where("taikai_transitions.to_state = 'done'")
      .where("EXTRACT(year FROM taikais.start_date) = ?", params[:year])
      #.where("taikais.category IN ('A')")

    @kinteki_taikais = @taikais
      .where("taikais.form IN ('individual', '2in1')")
      .where("taikais.scoring = 'kinteki'")
    @enteki_taikais = @taikais
      .where("taikais.form IN ('individual', '2in1')")
      .where("taikais.scoring = 'enteki'")

    @participant_scope = Participant


    @kinteki_participants = rank (
      Participant.joins(:participating_dojo)
        .where("participating_dojos.taikai_id IN (?)", @kinteki_taikais.pluck(:id)))
    @enteki_participants = rank (
      Participant.joins(:participating_dojo)
        .where("participating_dojos.taikai_id IN (?)", @enteki_taikais.pluck(:id)))


    render xlsx: 'export', filename: "Championat #{params[:year]} au #{Date.today.to_fs(:iso8601)}.xlsx"
  end

  private

  def rank(participants)
    result = participants
      .group_by { |participant| participant.display_name }
      .map do |display_name, participants|
        best_3 = participants
          .map { |participant|
            results = participant.score.results.first(12).select { |result| result.status == 'hit' }
            [participant, Score::ScoreValue::new(hits: results.count, value: results.map(&:value).compact.sum)]
          }
          .sort_by { |participant, score| score }
          .last(3)

        puts display_name
        puts best_3
        {
          display_name: display_name(best_3.first.first),
          club: best_3.first.first.club,
          total: best_3.sum { |participant, score_value| score_value }
        }
      end
      .sort_by { |participant| participant[:total] }.reverse
    result.each_with_index do |participant, index|
      participant[:rank] = index + 1
    end

    result
  end

  def display_name(participant)
    "#{participant.lastname.upcase} #{participant.firstname}"
  end
end
