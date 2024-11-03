class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.human_enum_value(enum_name, enum_value)
    if enum_value.nil?
      nil
    else
      I18n.t("activerecord.enums.#{model_name.i18n_key}.#{enum_name}.#{enum_value}",
             default: enum_value.humanize)
    end
  end

  class << self
    def human_enum(enum_name)
      send(:define_method, "human_#{enum_name}") do
        self.class.human_enum_value(enum_name, send(enum_name))
      end
    end
  end

  module RankedAssociationExtension
    def clear_ranks
      each { |rankable| rankable.update!(rank: nil, intermediate_rank: nil) }
    end

    def intermediate_ranked
      sort_by(&:intermediate_rank)
        .group_by(&:intermediate_rank)
        .each_value { |rankable| rankable.sort_by!(&:index) }
    end

    def ranked(validated = true)
      if proxy_association.owner.in_state? :tie_break, :done
        sort_by(&:rank)
          .group_by(&:rank)
          .each_value { |rankable| rankable.sort_by!(&:index) }
      else
        sort_by { |scoreable| scoreable.score.score_value(validated) }
          .reverse
          .group_by { |scoreable| scoreable.score.score_value(validated) } # group_by works on eq? & hash
          .each_value { |scoreables| scoreables.sort_by!(&:index) }
      end
    end

    def draw_ordered
      sort_by(&:index)
    end
  end

  def to_ascii
    to_s
  end
end
