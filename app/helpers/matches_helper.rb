module MatchesHelper
  def match_is_decidable?(match)
    match.finalized? &&
      !match.winner &&
      match.score(1) != match.score(2)
  end
end
