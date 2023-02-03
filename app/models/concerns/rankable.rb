module Rankable
  extend ActiveSupport::Concern

  included do
    scope :ranked, -> { order(rank: :asc) }
  end

  class_methods do
  end
end