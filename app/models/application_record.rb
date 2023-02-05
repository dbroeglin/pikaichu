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
      sort_by { |rankable| rankable.intermediate_rank }
        .group_by { |rankable| rankable.intermediate_rank }
        .each { |_, rankable| rankable.sort_by!(&:index) }
    end

    def ranked(validated = true)
      if proxy_association.owner.in_state? :tie_break, :done
        sort_by { |rankable| rankable.rank }
          .group_by { |rankable| rankable.rank }
          .each { |_, rankable| rankable.sort_by!(&:index) }
      else
        sort_by { |scoreable| scoreable.score(validated) }.reverse
          .group_by { |scoreable| scoreable.score(validated).score_value } # group_by works on eq? & hash
          .each { |_, scoreables| scoreables.sort_by!(&:index) }
      end
    end
  end
end
