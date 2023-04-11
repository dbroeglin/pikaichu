class ChampionshipController < ApplicationController

  def index
  end

  def export
    @taikais = Taikai
      .joins(:taikai_transitions)
      .order(:scoring, :start_date)
      .where("taikai_transitions.most_recent = true")
      .where("taikai_transitions.to_state = 'done'")
      .where("EXTRACT(year FROM taikais.start_date) = ?", params[:year])
      .where("taikais.category IN ('A', 'B', 'C')")

    @kinteki_taikais = @taikais
      .where("taikais.form IN ('individual', '2in1')")
      .where("taikais.scoring = 'kinteki'")
    @enteki_taikais = @taikais
      .where("taikais.form IN ('individual', '2in1')")
      .where("taikais.scoring = 'enteki'")

    @kinteki_participants = Participant.joins(:participating_dojo)
      .includes(participating_dojo: :taikai)
      .where("participating_dojos.taikai_id IN (?)", @kinteki_taikais.pluck(:id))
      .map do |participant|
        [participant, participant.score.first(12).score_value]
      end
    @enteki_participants  = Participant.joins(:participating_dojo)
      .includes(participating_dojo: :taikai)
      .where("participating_dojos.taikai_id IN (?)", @enteki_taikais.pluck(:id))
      .map do |participant|
        [participant, participant.score.first(12).score_value]
      end

    @kinteki_individual = rank @kinteki_participants
    @enteki_individual = rank @enteki_participants

    render xlsx: 'export', filename: "Championat #{params[:year]} au #{Date.today.to_fs(:iso8601)}.xlsx"
  end

  private

  def rank(participants)
    result = participants
      .group_by { |participant, _| participant.display_name }
      .map do |display_name, pairs|

        best_3 = pairs
          .sort_by { |participant, score| score }
          .last(3)

        {
          participant: best_3.first.first,
          club: best_3.first.first.club,
          total: best_3.sum(Score::ScoreValue::new(hits: 0)) { |participant, score_value| score_value }
        }
      end
      .sort_by { |participant| participant[:total] }.reverse

    result.each_with_index do |participant, index|
      participant[:rank] = index + 1
    end

    result
  end
end
