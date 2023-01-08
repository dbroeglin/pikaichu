module Scorable
  extend ActiveSupport::Concern

  included do
    has_many :scores,  dependent: :destroy
  end

  class_methods do
  end
end