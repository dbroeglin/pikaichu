module LeaderboardHelper

  def display_rank(taikai, rankable, calculated_rank)
    if taikai.in_state? :tie_break, :done
      rankable.rank
    else
      "<i>#{calculated_rank}</i>".html_safe
    end
  end
end
