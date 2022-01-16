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
      self.send(:define_method, "human_#{enum_name}") do
        self.class.human_enum_value(enum_name, self.send(enum_name))
      end
    end
  end
end
