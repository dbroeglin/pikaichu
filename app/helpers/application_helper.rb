module ApplicationHelper
  class BulmaFormBuilder < ActionView::Helpers::FormBuilder
    delegate :tag, :safe_join, to: :@template

    # Create a form input (behaves similarily to simple_form)
    def input(method, options = {})
      @form_options = options
      object_type = object_type_for_method(method)
      input_type = input_type_for_object_type(object_type, options)

      send("#{input_type}_input", method, options)
    end

    # Generates a label
    def label(method, options = {})
      options = {} if options.nil?
      options[:class] = [options[:class], 'label'].join ' '
      super
    end

    private

    def collection_input(method, options, &block)
      field_div(method, options) do
        safe_join [
                    label(method, options[:label]),
                    (
                      tag.div class: 'select' do
                        block.call
                      end
                    ),
                  ]
      end
    end

    def enum_input(method, options = {})
      field_div(method, options) do
        collection = @object.class.send(method.to_s.pluralize).map do |key, value|
          [key, @object.class.human_enum_name(method, key)]
        end
        safe_join [
                    label(method, options[:label]),
                    (
                      tag.div class: 'select' do
                        collection_select(
                          method,
                          collection,
                          :first,
                          :last,
                          options,
                          merge_input_options(
                            {
                              class:
                                "select #{'is-invalid' if has_error?(method)}",
                            },
                            options[:input_html],
                          ),
                        )
                                      end
                    ),
                  ]
      end
    end

    def string_input(method, options = {})
      field_div(method, options) do
        safe_join [
                    (
                      unless options[:label] == false
                        label(method, options[:label])
                      end
                    ),
                    (
                      tag.div class: 'control' do
                        string_control(
                          method,
                          merge_input_options(
                            {
                              class:
                                "input #{'is-danger' if has_error?(method)}",
                            },
                            options[:input_html],
                          ),
                        )
                      end
                    ),
                  ]
      end
    end

    def select_input(method, options = {})
      value_method = options[:value_method] || :to_s
      text_method = options[:text_method] || :to_s
      input_options = options[:input_html] || {}

      multiple = input_options[:multiple]

      collection_input(method, options) do
        collection_select(
          method,
          options[:collection],
          value_method,
          text_method,
          options,
          merge_input_options(
            {
              class:
                "#{'select' unless multiple} #{'is-invalid' if has_error?(method)}",
            },
            options[:input_html],
          ),
        )
      end
    end

    def boolean_input(method, options = {})
      field_div(method, options) do
        label(method, options) do
          safe_join [
                      check_box(
                        method,
                        merge_input_options(
                          { class: 'checkbox' },
                          options[:input_html],
                        ),
                      ),
                      " #{object.class.human_attribute_name(method).html_safe}",
                    ]
        end
      end
    end

    def text_input(method, options = {})
      field_div(method, options) do
        safe_join [
                    (
                      unless options[:label] == false
                        label(method, options[:label])
                      end
                    ),
                    text_area(
                      method,
                      merge_input_options(
                        {
                          class:
                            "textarea #{'is-invalid' if has_error?(method)}",
                        },
                        options[:input_html],
                      ),
                    ),
                  ]
      end
    end

    def string_control(method, options = {})
      case object_type_for_method(method)
      when :date
        birthday = method.to_s =~ /birth/
        date_field(
          method,
          merge_input_options(options, { data: { datepicker: true } }),
        )
      when :integer
        number_field(method, options)
      when :string
        case method.to_s
        when /password/
          password_field(method, options)
          # when /time_zone/ then :time_zone
          # when /country/   then :country
        when /email/
          email_field(method, options)
        when /phone/
          telephone_field(method, options)
        when /url/
          url_field(method, options)
        else
          text_field(method, options)
        end
      end
    end

    # Compute the type of object we deal with
    def object_type_for_method(method)
      result =
        if @object.respond_to?(:type_for_attribute) &&
             @object.has_attribute?(method)
          @object.type_for_attribute(method.to_s).try(:type)
        elsif @object.respond_to?(:column_for_attribute) &&
              @object.has_attribute?(method)
          @object.column_for_attribute(method).try(:type)
        end

      result || :string
    end

    # Computes the type of input we will use to edit the object
    def input_type_for_object_type(object_type, options)
      input_type =
        case object_type
        when :date
          :string
        when :integer
          :string
        else
          object_type
        end

      if options[:as]
        options[:as]
      elsif options[:collection]
        :select
      else
        input_type
      end
    end

    def field_div(method, options = {}, &block)
      tag.div class: 'field' do
        safe_join [
                    block.call,
                    #hint_text(options[:hint]),
                    error_text(method),
                  ].compact
      end
    end

    # def hint_text(text)
    #   return if text.nil?
    #   tag.small text, class: "form-text text-muted"
    # end

    def error_text(method)
      @object
        .errors
        .where(method)
        .map { |error| tag.div error.full_message, class: 'help is-danger' }
    end

    def has_error?(method)
      return false unless @object.respond_to?(:errors)
      @object.errors.key?(method)
    end

    def merge_input_options(options, user_options)
      return options if user_options.nil?

      # TODO handle class merging here
      options.merge(user_options)
    end
  end

  def bulma_form_for(name, *args, &block)
    options = args.extract_options!
    args << options.merge(builder: BulmaFormBuilder)
    form_for(name, *args, &block)
  end

  def bulma_form_with(
    model: nil,
    scope: nil,
    url: nil,
    format: nil,
    **options,
    &block
  )
    options = options.reverse_merge(builder: BulmaFormBuilder)
    form_with(
      model: model,
      scope: scope,
      url: url,
      format: format,
      **options,
      &block
    )
  end
end
