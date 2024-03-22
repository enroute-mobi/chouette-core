module Search
  class Base
    extend ActiveModel::Naming

    include ActiveModel::Validations

    include ActiveAttr::Attributes
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults

    attr_accessor :saved_name, :saved_description

    def initialize(attributes = {})
      apply_defaults

      order.attributes = attributes.delete :order if attributes[:order]
      attributes.each { |k, v| send "#{k}=", v }
    end

    def self.from_params(params, attributes = {})
      Rails.logger.debug "[Search] Raw params: #{params.inspect}"

      new(attributes).tap do |search|
        search.attributes = FromParamsBuilder.new(params).attributes
        Rails.logger.debug "[Search] #{search.inspect}"
      end
    end

    def inspect
      "#{self.class.name}(#{attributes.inspect},order=#{order.attributes.inspect})"
    end

    attr_reader :saved_search

    def persisted?
      saved_search.present?
    end

    def saved_search=(saved_search)
      @saved_search = saved_search

      self.saved_name = saved_search.name
      self.saved_description = saved_search.description
    end

    # TODO: Why the default ActiveAttr::AttributeDefaults#apply_defaults
    # defines @attributes values without writing the attributes ?
    def apply_defaults(defaults = attribute_defaults)
      defaults.each do |name, value|
        write_attribute name, value
      end
    end

    def attributes=(attributes = {})
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)

      if attributes[:order]
        order.attributes = attributes.delete :order
      else
        order.use_defaults
      end

      # Only used defined attributes
      self.class.attributes.each_key do |attribute_name|
        if (value = attributes[attribute_name]).present?
          write_attribute attribute_name, value
        end
      end
    end

    def attributes
      super.delete_if { |_k, v| v.blank? }
    end

    # Create Search attributes from our legacy Controller params (:sort, :direction, :page, etc)
    class FromParamsBuilder
      def initialize(params = nil)
        @params = params || {}
      end
      attr_reader :params

      def attributes
        {}.tap do |attributes|
          attributes.merge! search_params

          attributes[:order] = { sort_attribute => sort_direction } if sort_attribute
          attributes[:page] = page
          attributes[:per_page] = per_page

          attributes.delete_if { |_, v| v.blank? }
        end
      end

      def page
        params[:page]
      end

      def per_page
        params[:per_page]
      end

      def sort_attribute
        params[:sort]&.to_sym
      end

      def sort_direction
        params[:direction]&.to_sym || :asc
      end

      def search_params
        (params[:search] || {}).tap do |search_params|
          search_params.try(:permit!)
        end
      end
    end

    # Requires to create a form
    def to_key; end

    validates :page, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :per_page, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true

    # Could be useful for i18n .. but change the params root key
    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, 'Search')
    end

    def without_order
      @without_order = true
      self
    end

    def without_order?
      @without_order
    end

    def without_pagination
      @without_pagination = true
      self
    end

    def without_pagination?
      @without_pagination
    end

    def query(_scope)
      raise 'Not yet implemented'
    end

    def search(scope)
      if valid?
        result = query(scope).scope
        result = order.order(result) unless without_order?
        result = result.paginate(paginate_attributes) unless without_pagination?
        result
      else
        Rails.logger.debug "[Search] Invalid attributes: #{errors.full_messages}"
        scope.none
      end
    end

    def order
      # Use the local/specific Order class
      @order ||= self.class.const_get('Order').new
    end

    attribute :page, type: Integer
    attribute :per_page, type: Integer, default: 30

    def paginate_attributes
      { per_page: per_page, page: page }
    end
  end

  class Order
    def initialize(attributes = {})
      self.attributes = attributes
    end

    def self.defaults
      attributes.each_with_object({}) do |attribute, defaults|
        defaults.merge!(attribute.name => attribute.default) if attribute.default?
      end
    end

    def attributes
      self.class.attributes.map do |attribute|
        if (attribute_order = send(attribute.name))
          [attribute.name, attribute_order]
        end
      end.compact.to_h
    end

    def order_hash
      self.class.attributes.map do |attribute|
        if (attribute_order = send(attribute.name))
          [attribute.column, attribute_order]
        end
      end.compact.to_h
    end

    def joins
      self.class.attributes.map do |attribute|
        attribute.joins if send(attribute.name)
      end.compact.flatten
    end

    def attributes=(attributes = {})
      attributes.each do |attribute, attribute_order|
        attribute_method = "#{attribute}="
        # Ignore invalid attribute
        send attribute_method, attribute_order if respond_to?(attribute_method)
      end
    end

    def use_defaults
      self.attributes = self.class.defaults
    end

    def order(scope)
      scope = scope.joins(joins) if joins.present?
      scope.order(order_hash)
    end

    class_attribute :attributes, instance_accessor: false, default: []

    # TODO: Attributes can only return values :asc, :desc or nil (for securiy reason)
    # Attributes can be set with "asc", :asc, 1 to have the :asc value
    # Attributes can be set with "desc", :desc, -1 to have the :desc value
    # Attributes can be set with nil, 0 to have the nil value
    #
    # These methods ensures that the sort attribute is supported and valid
    def self.attribute(name, options = {})
      attribute = Attribute.new(name, options)

      define_method "#{name}=" do |value|
        value = attribute.order(value)
        instance_variable_set "@#{name}", value
      end
      attr_reader name

      # Don't use attributes << name, see class_attribute documentation
      self.attributes += [attribute]
    end

    # Describe a given atribute (name, etc) and its options (default, etc)
    class Attribute
      ASCENDANT_VALUES = [:asc, 'asc', 1].freeze
      DESCENDANT_VALUES = [:desc, 'desc', -1].freeze

      def initialize(name, options)
        @name = name

        options.each do |option, value|
          send "#{option}=", value
        end
      end

      attr_reader :name

      def joins=(joins)
        @joins = Array(joins)
      end

      def joins
        @joins ||= []
      end

      attr_writer :column

      def column
        @column ||= name
      end

      attr_accessor :default

      def default?
        @default.present?
      end

      def order(value)
        if ASCENDANT_VALUES.include?(value)
          :asc
        elsif DESCENDANT_VALUES.include?(value)
          :desc
        end
      end
    end
  end
end
