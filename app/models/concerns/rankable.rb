module Rankable
  extend ActiveSupport::Concern

  included do
    attr_accessor :rank

    scope :ranked, -> { order(rank: :asc) }

  end

  class_methods do
  end
end