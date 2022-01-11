module LeaderboardHelper
  def final_icon_from(result)
    if result.final?
      icon_from(result)
    else
      ''
    end
  end
end
