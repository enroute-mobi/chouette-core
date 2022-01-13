module TableBuilderHelper
  class Column
    attr_reader :key, :name, :attribute, :sortable

    def initialize(key: nil, name: nil, attribute:, sortable: true, link_to: nil, **opts)
      raise ColumnMustHaveKeyOrNameError if name != false && key.nil? && name.empty?

      opts ||= {}
      @key = key
      name = '' if name == false
      @name = name
      @attribute = attribute
      @sortable = sortable
      @link_to = link_to
      @condition = opts[:if]
      @extra_class = opts[:class]
    end

    def value(obj)
      return unless check_condition(obj)
      if @attribute.is_a?(Proc)
        @attribute.call(obj)
      else
        obj.try(@attribute)
      end
    end

    def header_label(model = nil)
      return @name unless @name.nil?

      # Transform `Chouette::Line` into "line"
      model_key = model.model_name.i18n_key.to_s
      I18n.t("activerecord.attributes.#{model_key}.#{@key}")
    end

    def linkable?
      !@link_to.nil?
    end

    def link_to(obj)
      return unless check_condition(obj)
      @link_to.call(obj)
    end

    def check_condition(obj)
      condition_val = true
      if @condition.present?
        condition_val = @condition
        condition_val = condition_val.call(obj) if condition_val.is_a?(Proc)
      end
      !!condition_val
    end

    def td_class(obj)
      out = []
      out << @attribute if @attribute.is_a?(String) || @attribute.is_a?(Symbol)
      out << @extra_class
      out = out.compact.join ' '
      out.present? ? out : nil
    end
  end


  class ColumnMustHaveKeyOrNameError < StandardError; end
end
