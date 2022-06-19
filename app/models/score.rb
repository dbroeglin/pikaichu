class Score
  include Comparable
  attr_reader :hits
  attr_reader :value

  def initialize(hits, value)
    @hits, @value = hits, value
  end

  def <=>(other)
    result = @value <=> other.value
    return result if result != 0
    @hits <=> other.hits
  end

  def ==(other)
    return false if other.nil?

    hits == other.hits && value == other.value
  end

  def +(other)
    Score.new(hits + other.hits, value + other.value)
  end

  def -@
    Score.new(-hits, -value)
  end

  def to_s
    "Score: #{value} / #{hits}"
  end
end