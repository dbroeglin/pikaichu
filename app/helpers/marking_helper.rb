module MarkingHelper
  def icon_from(result)
    case result.status
    when 'hit' then '<i class="far fa-circle"></i>'
    when 'miss' then '<i class="fas fa-xmark"></i>'
    when 'unknown' then '<i class="fas fa-question"></i>'
    else ''
    end.html_safe
  end
end
