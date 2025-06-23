# frozen_string_literal: true

module ActiveModel
  class Name
    def the_human(options = {})
      x_human('the', options)
    end

    def of_human(options = {})
      x_human('of', options)
    end

    def to_human(options = {})
      x_human('to', options)
    end

    private

    def x_human(x, options) # rubocop:disable Naming/MethodParameterName
      default = "#{x} #{@human}"

      return default unless @klass.respond_to?(:lookup_ancestors) &&
                            @klass.respond_to?(:i18n_scope)

      defaults = @klass.lookup_ancestors.map do |klass|
        :"#{klass.model_name.i18n_key}.#{x}"
      end

      defaults << options[:default] if options[:default]
      defaults << default

      options = { scope: [@klass.i18n_scope, :models], count: 1, default: defaults }.merge!(options.except(:default))
      I18n.translate(defaults.shift, **options)
    end
  end
end
