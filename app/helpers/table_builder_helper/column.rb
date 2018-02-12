module TableBuilderHelper
  class Column
    attr_reader :key, :name, :attribute, :sortable

    def initialize(key: nil, name: '', attribute:, sortable: true, link_to: nil, **opts)
      if key.nil? && name.empty?
        raise ColumnMustHaveKeyOrNameError
      end
      opts ||= {}
      @key = key
      @name = name
      @attribute = attribute
      @sortable = sortable
      @link_to = link_to
      @condition = opts[:if]
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
      return @name if @name.present?

      # Transform `Chouette::Line` into "line"
      model_key = model.to_s.demodulize.underscore

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
  end


  class ColumnMustHaveKeyOrNameError < StandardError; end
end
