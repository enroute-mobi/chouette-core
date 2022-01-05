module Search
  class Base
    extend ActiveModel::Naming

    include ActiveModel::Validations

    include ActiveAttr::Attributes
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults

    def initialize(scope, params = nil, context = {})
      apply_defaults

      @scope = scope

      context.each { |k,v| send "#{k}=", v }

      params = self.class.params(params.dup)

      Rails.logger.debug "[Search] Params: #{params.inspect}"

      if params[:order]
        order.attributes = params.delete :order
      else
        order.use_defaults
      end

      self.attributes = params

      Rails.logger.debug "[Search] #{self.class.name}(#{attributes.inspect},order=#{order.attributes.inspect})"
    end
    attr_reader :scope

    # TODO Why the default ActiveAttr::AttributeDefaults#apply_defaults
    # defines @attributes values without writing the attributes ?
    def apply_defaults(defaults=attribute_defaults)
      defaults.each do |name, value|
        write_attribute name, value
      end
    end

    def attributes=(attributes = {})
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)

      # Only used defined attributes
      self.attributes.keys.each do |attribute_name|
        if attributes.has_key? attribute_name
          write_attribute attribute_name, attributes[attribute_name]
        end
      end
    end

    def self.params(params)
      return {} if params.nil?
      Rails.logger.debug "[Search] Raw params: #{params.inspect}"

      params[:search] ||= {}

      # Transform 'legacy' parameters into order params
      if params[:sort]
        sort_attribute = params.delete(:sort).to_sym
        sort_direction = params.delete(:direction).presence || :asc

        params[:search][:order] = { sort_attribute => sort_direction.to_sym }
      end

      %i{page per_page}.each do |param|
        params[:search][param] = params[param] if params[param]
      end

      search_params = params[:search]

      if search_params.respond_to?(:permit!)
        search_params.permit!
      else
        search_params
      end
    end

    # Requires to create a form
    def to_key; end

    validates :page, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :per_page, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true

    # Could be useful for i18n .. but change the params root key
    # def self.model_name
    #   model_name =
    #     if name =~ /^(.*)Controller::Search$/
    #       "Search::#{$1}"
    #     else
    #       'Search'
    #     end
    #   ActiveModel::Name.new(self, nil, model_name)
    # end

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, 'Search')
    end

    def query
      raise "Not yet implemented"
    end

    def collection
      if valid?
        query.scope.order(order.to_hash).paginate(paginate_attributes)
      else
        Rails.logger.debug "[Search] invalid attributes: #{errors.full_messages}"
        scope.none
      end
    end

    def order
      # Use the local/specific Order class
      @order ||= self.class.const_get("Order").new
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

    class_attribute :attributes, instance_accessor: false, default: []
    class_attribute :defaults, instance_accessor: false, default: {}

    # TODO: Attributes can only return values :asc, :desc or nil (for securiy reason)
    # Attributes can be set with "asc", :asc, 1 to have the :asc value
    # Attributes can be set with "desc", :desc, -1 to have the :desc value
    # Attributes can be set with nil, 0 to have the nil value
    #
    # These methods ensures that the sort attribute is supported and valid
    def self.attribute(name, default: nil)
      name = name.to_sym

      define_method "#{name}=" do |value|
        value =
          if ASCENDANT_VALUES.include?(value)
            :asc
          elsif DESCENDANT_VALUES.include?(value)
            :desc
          end
        instance_variable_set "@#{name}", value
      end
      attr_reader name

      # Don't use attributes << name, see class_attribute documentation
      self.attributes += [ name ]
      self.defaults = defaults.merge(name => default) if default
    end

    ASCENDANT_VALUES = [:asc, "asc", 1].freeze
    DESCENDANT_VALUES = [:desc, "desc", -1].freeze

    def attributes
      self.class.attributes.map do |attribute|
        if (attribute_order = send(attribute))
          [ attribute, attribute_order ]
        end
      end.compact.to_h
    end
    alias to_hash attributes

  end
end
