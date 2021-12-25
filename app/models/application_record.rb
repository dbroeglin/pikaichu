class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.human_enum_value(enum_name, enum_value)
    I18n.t("activerecord.enums.#{model_name.i18n_key}.#{enum_name}.#{enum_value}",
           default: human_attribute_name(enum_value))
  end
end
