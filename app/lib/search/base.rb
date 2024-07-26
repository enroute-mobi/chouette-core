# frozen_string_literal: true

module Search
  class Base
    extend ActiveModel::Naming
    extend Enumerize

    include ActiveModel::Validations

    include ActiveAttr::Attributes
    include ActiveAttr::TypecastedAttributes
    include ActiveAttr::AttributeDefaults

    attribute :page, type: Integer
    attribute :per_page, type: Integer, default: 30
    attribute :chart_type, type: String
    attribute :group_by_attribute, type: String
    attribute :first, type: Boolean, default: false # meaningless if attribute is in DATE_GROUP_BY_ATTRIBUTES
    attribute :top_count, type: Integer, default: 30 # meaningless if attribute is in NO_LIMIT_DATE_GROUP_BY_ATTRIBUTES
    # "value" meaningless if attribute is in DATE_GROUP_BY_ATTRIBUTES
    # "label" meaningless if attribute is in DATE_GROUP_BY_ATTRIBUTES or all_group_by_attribute_keys is defined
    attribute :sort_by, type: String, default: 'value'
    attribute :aggregate_operation, type: String, default: 'count'
    attribute :aggregate_attribute, type: String
    attribute :display_percent, type: Boolean

    attr_accessor :saved_name, :saved_description

    enumerize :chart_type, in: %w[line pie column], i18n_scope: 'enumerize.search.chart_type'
    enumerize :sort_by, in: %w[value label], i18n_scope: 'enumerize.search.sort_by'
    enumerize :aggregate_operation, in: %w[count sum average], i18n_scope: 'enumerize.search.aggregate_operation'

    with_options if: :graphical? do
      validates :group_by_attribute, inclusion: { in: ->(r) { r.authorized_group_by_attributes } }
      validates :top_count, presence: true, numericality: { only_integer: true, greater_than: 1 }
      validates :sort_by, presence: true
      validates :aggregate_operation, presence: true
      validates :aggregate_attribute, inclusion: { in: ->(r) { r.numeric_attributes.keys } }, if: :aggregate_attribute?
    end

    SAVED_SEARCH_ATTRIBUTE_MAPPING = {
      name: :saved_name,
      description: :saved_description
    }.freeze

    AUTHORIZED_GROUP_BY_ATTRIBUTES = %w[
      date
      hour_of_day
      day_of_week
    ].freeze

    NUMERIC_ATTRIBUTES = {}.freeze

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

      SAVED_SEARCH_ATTRIBUTE_MAPPING.each do |k, v|
        self[v] = saved_search[k]
      end

      errors.copy!(saved_search.errors)
      rewrite_keys = ->(k) { SAVED_SEARCH_ATTRIBUTE_MAPPING[k] }
      errors.messages.transform_keys!(&rewrite_keys)
      errors.details.transform_keys!(&rewrite_keys)
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

    def authorized_group_by_attributes
      self.class::AUTHORIZED_GROUP_BY_ATTRIBUTES
    end

    def numeric_attributes
      self.class::NUMERIC_ATTRIBUTES
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

    def graphical?
      chart_type.present?
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

    def chart(scope) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      return nil unless valid? && graphical?

      models = without_order.without_pagination.search(scope)
      self.class.const_get('Chart').new(
        models,
        type: chart_type,
        group_by_attribute: group_by_attribute,
        first: first,
        top_count: top_count,
        sort_by: sort_by,
        aggregate_operation: aggregate_operation,
        aggregate_attribute: aggregate_attribute ? numeric_attributes[aggregate_attribute] : nil,
        display_percent: display_percent
      )
    end

    def order
      # Use the local/specific Order class
      @order ||= self.class.const_get('Order').new
    end

    def paginate_attributes
      { per_page: per_page, page: page }
    end

    class Chart
      def initialize(
        models,
        type:,
        group_by_attribute:,
        first:,
        top_count:,
        sort_by:,
        aggregate_operation:,
        aggregate_attribute:,
        display_percent:
      )
        @models = models
        @type = type
        @group_by_attribute = group_by_attribute
        @first = first
        @top_count = top_count
        @sort_by = sort_by
        @aggregate_operation = aggregate_operation
        @aggregate_attribute = aggregate_attribute
        @display_percent = display_percent
      end
      attr_reader :models,
                  :type,
                  :group_by_attribute,
                  :first,
                  :top_count,
                  :sort_by,
                  :aggregate_operation,
                  :aggregate_attribute,
                  :display_percent

      def raw_data
        request = models
        request = joins(request)
        request = select(request)
        request = group_order_limit(request)
        aggregate(request)
      end

      def data
        data = raw_data
        data = compute_percent(data)
        data = add_missing_keys(data)
        label_keys(data)
      end

      def to_chartkick(view_context)
        chart_data = data

        options = {}
        options[:suffix] = '%' if display_percent
        if add_missing_keys?
          keys = send(all_keys_method_name)
          options[:xmin] = keys.first
          options[:xmax] = keys.last
        end

        view_context.send("#{type}_chart", chart_data, options)
      end

      private

      def joins(request)
        return request unless respond_to?(joins_for_label_of_method_name, true)

        request.joins(send(joins_for_label_of_method_name))
      end

      def joins_for_label_of_method_name
        @joins_for_label_of_method_name ||= :"joins_for_label_of_#{group_by_attribute}"
      end

      def select(request)
        return request unless selects.any?

        request.select(*selects)
      end

      def selects
        @selects ||= if respond_to?(select_for_label_of_method_name, true)
                       send(select_for_label_of_method_name)
                     else
                       []
                     end
      end

      def select_for_label_of_method_name
        @select_for_label_of_method_name ||= :"select_for_label_of_#{group_by_attribute}"
      end

      def group_order_limit(request)
        if date_group_by_attribute?
          request.send(group_by_attribute_method, :created_at, **group_by_attribute_method_options)
        else
          request.group(group_by_attribute, *selects).order(order_arg).limit(top_count)
        end
      end

      DATE_GROUP_BY_ATTRIBUTES = {
        'date' => :group_by_day,
        'hour_of_day' => :group_by_hour_of_day,
        'day_of_week' => :group_by_day_of_week
      }.freeze
      NO_LIMIT_DATE_GROUP_BY_ATTRIBUTES = %w[hour_of_day day_of_week].to_set.freeze

      def date_group_by_attribute?
        DATE_GROUP_BY_ATTRIBUTES.key?(group_by_attribute)
      end

      def group_by_attribute_method
        DATE_GROUP_BY_ATTRIBUTES[group_by_attribute]
      end

      def group_by_attribute_method_options
        if NO_LIMIT_DATE_GROUP_BY_ATTRIBUTES.include?(group_by_attribute)
          {}
        else
          { last: top_count }
        end
      end

      def order_arg
        asc_desc = first ? :asc : :desc

        if sort_by == 'label'
          if selects.any?
            selects.map { |s| [s, asc_desc] }.to_h
          else
            { group_by_attribute => asc_desc }
          end
        else
          { order_aggregate_alias => asc_desc }
        end
      end

      def order_aggregate_alias
        if aggregate_operation == 'count'
          :count_id
        else
          models.send(:column_alias_for, "#{aggregate_operation} #{aggregate_attribute}")
        end
      end

      def aggregate(request)
        if aggregate_operation == 'count'
          request.count(:id)
        else
          request.send(aggregate_operation, aggregate_attribute)
        end
      end

      def compute_percent(result)
        return result unless display_percent

        sum = result.values.sum
        if sum.zero?
          result
        else
          result.transform_values { |v| v * 100.0 / sum }
        end
      end

      def add_missing_keys?
        respond_to?(all_keys_method_name, true)
      end

      def add_missing_keys(data)
        if add_missing_keys?
          send(all_keys_method_name).map { |k| [k, 0] }.to_h.merge(data)
        else
          data
        end
      end

      def all_keys_method_name
        @all_keys_method_name ||= :"all_#{group_by_attribute}_keys"
      end

      def all_hour_of_day_keys
        0..23
      end

      def all_day_of_week_keys
        0..6
      end

      def label_keys(data)
        if respond_to?(label_key_method_name, true)
          data.transform_keys { |k| send(label_key_method_name, k) }
        else
          data
        end
      end

      def label_key_method_name
        @label_key_method_name ||= :"label_#{group_by_attribute}_key"
      end

      def label_day_of_week_key(key)
        I18n.t('date.day_names')[key]
      end
    end

    private

    def aggregate_attribute?
      aggregate_operation.in?(%w[sum average])
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
