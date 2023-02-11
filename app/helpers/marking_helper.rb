module MarkingHelper

  def full_icon_from(result, final = false)
    if result.value.nil?
      "<span class='icon is-small' title='#{Result.human_enum_value(:status, result.status)}'>#{icon_from(result, final)}</span>"
    else
      icon_from(result, final)
    end.html_safe
  end

  def icon_from(result, final = false)
    return '' if result.nil? || final && !result.final?
    if result.value.nil?
      case result.status
      when 'hit' then '<i class="far fa-circle"></i>'
      when 'miss' then '<i class="fas fa-times"></i>'
      when 'unknown' then '<i class="fas fa-question"></i>'
      else ''
      end
    else
      "<span class='is-size-6'>#{result.value}</span>"
    end.html_safe
  end

  def display_participant_score(participant, final, match_id)
    score = participant.score(match_id)
    display_score score, participant.taikai.scoring_enteki?
  end

  def display_score(score, enteki)
    if score.nil?
      return enteki ? "0&nbsp;/&nbsp;0".html_safe : "0"
    end
    if enteki
      "#{score.value}&nbsp;/&nbsp;#{score.hits}".html_safe
    else
      score.hits.to_s
    end
  end

  def display_score_axlsx(score, enteki)
    if score.nil?
      return enteki ? "0 / 0" : "0"
    end
    if enteki
      "#{score.value} / #{score.hits}".html_safe
    else
      score.hits.to_s
    end
  end

  def display_round_tally(participant, results)
    hits = results.map(&:status).tally['hit'] || 0
    if participant.taikai.scoring_enteki?
      "#{results.map(&:value).compact.sum}&nbsp;/&nbsp;#{hits}".html_safe
    else
      hits.to_s
    end
  end
end
