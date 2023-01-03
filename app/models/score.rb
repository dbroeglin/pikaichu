class Score < ApplicationRecord
  include Comparable

  def <=>(other)
    result = value <=> other.value
    return result if result != 0
    hits <=> other.hits
  end

  def ==(other)
    return false if other.nil?

    hits == other.hits && value == other.value
  end

  def +(other)
    Score.new(hits: hits + other.hits, value: value + other.value)
  end

  def -@
    Score.new(hits: -hits, value: -value)
  end

  def to_s
    "Score: #{value} / #{hits}"
  end
end