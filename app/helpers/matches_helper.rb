module MatchesHelper
  def match_is_decidable?(match)
    match.finalized? &&
      !match.winner &&
      match.score1(true) != match.score2(true)
  end
end
