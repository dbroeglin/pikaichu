module MatchesHelper
  def match_is_decidable?(match)
    match.finalized? &&
      !match.winner &&
      match.score(1)&.score_value != match.score(2)&.score_value
  end
end
