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

    enumerize :chart_type, in: %w[line pie column]
    enumerize :sort_by, in: %w[value label]
    enumerize :aggregate_operation, in: %w[count sum average]

    with_options if: :graphical? do
      validates :group_by_attribute, inclusion: { in: ->(r) { r.candidate_group_by_attributes.keys } }
      validates :top_count, presence: true, numericality: { only_integer: true, greater_than: 1 }
      validates :sort_by, presence: true
      validates :aggregate_operation, presence: true
      validates :aggregate_attribute,
                inclusion: { in: ->(r) { r.candidate_aggregate_attributes.keys } },
                if: :aggregate_attribute?
    end

    SAVED_SEARCH_ATTRIBUTE_MAPPING = {
      name: :saved_name,
      description: :saved_description
    }.freeze

    def initialize(attributes = {})
      apply_defaults
      order.attributes = attributes.delete :order if attributes[:order]
      attributes.each { |k, v| send "#{k}=", v }
    end

    class << self
      def chart_periods
        @chart_periods ||= {}
      end

      def inherited(base)
        base.instance_variable_set(:@chart_periods, chart_periods.dup)
        super
      end

      def period(name, from, to, **options)
        period = Period.new(name, from, to, **options)

        define_method name do
          ::Period.new(from: send(from), to: send(to)).presence
        end
        validates name, valid: true

        period.chart_attributes.each do |attr|
          chart_periods[attr.to_s] = period
        end
      end

      def from_params(params, attributes = {})
        Rails.logger.debug "[Search] Raw params: #{params.inspect}"

        new(attributes).tap do |search|
          search.attributes = FromParamsBuilder.new(params).attributes
          Rails.logger.debug "[Search] #{search.inspect}"
        end
      end

      class Period
        def initialize(name, from, to, **options)
          @name = name
          @from = from
          @to = to
          @chart_attributes = (options[:chart_attributes] || [from, to]).freeze
        end
        attr_reader :name, :from, :to, :chart_attributes

        def chart_period(search)
          search.send(name)
        end
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

    def searched_class
      raise NotImplementedError
    end
    delegate :human_attribute_name, to: :searched_class

    def candidate_group_by_attributes
      chart_klass.group_by_attributes
    end

    def candidate_aggregate_attributes
      chart_klass.aggregate_attributes
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

    def chart(scope) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      return nil unless valid? && graphical?

      chart_klass.new(
        without_order.without_pagination.search(scope),
        type: chart_type,
        group_by_attribute: group_by_attribute,
        first: first,
        top_count: top_count,
        sort_by: sort_by,
        aggregate_operation: aggregate_operation,
        aggregate_attribute: aggregate_attribute,
        display_percent: display_percent,
        period: self.class.chart_periods[chart_klass.group_by_attributes[group_by_attribute].name]&.chart_period(self)
      )
    end

    def chart_klass
      self.class.const_get(:Chart)
    end

    def order
      # Use the local/specific Order class
      @order ||= self.class.const_get('Order').new
    end

    def paginate_attributes
      { per_page: per_page, page: page }
    end

    def scope(initial_scope)
      initial_scope
    end

    class Chart
      class GroupByAttribute
        class << self
          private

          def method_added(name)
            if name == :label
              define_method(:label?) do
                true
              end
            end

            super
          end
        end

        def initialize(name, sub_type: false, keys: nil, joins: nil, selects: nil, sortable: :after_label)
          @name = name
          @sub_type = sub_type
          @keys = keys
          @joins = joins
          @selects = selects
          @sortable = sortable
        end
        attr_reader :name, :sub_type, :keys, :joins, :selects, :sortable

        def human_name(klass)
          human_name = klass.human_attribute_name(name)
          human_name = "#{human_name} (#{subtype_human_name})" if sub_type
          human_name
        end

        def label?
          false
        end

        def discrete?
          keys
        end

        def keys_zero_data
          @keys_zero_data ||= keys.map { |k| [k, 0] }.to_h.freeze
        end

        def nil_key?(key)
          array? ? key.all?(&:nil?) : key.nil?
        end

        def delete_and_return_nil_key!(data)
          if array?
            nil_key = data.keys.find { |k| nil_key?(k) }
            data.delete(nil_key) if nil_key
          else
            data.delete(nil)
          end
        end

        def array?
          @array ||= selects && selects.length > 1
        end

        def groups
          @groups ||= selects || [name]
        end

        def group_order_limit(request, order_arg, top_count, _period)
          request.group(*groups).order(order_arg).limit(top_count)
        end

        def order_arg(request, asc_desc)
          groups.map { |s| [request.send(:column_alias_for, s), asc_desc] }.to_h
        end

        protected

        def subtype_human_name
          nil
        end
      end

      class StringGroupByAttribute < GroupByAttribute
        def discrete?
          true
        end
      end

      class NumericGroupByAttribute < GroupByAttribute
      end

      class DatetimeGroupByAttribute < GroupByAttribute
        def group_order_limit(request, _order_arg, top_count, period)
          request.group_by_day(groups[0], last: top_count, range: period, time_zone: time_zone)
        end

        protected

        def time_zone
          nil
        end

        class ByWeek < DatetimeGroupByAttribute
          def group_order_limit(request, _order_arg, top_count, period)
            request.group_by_week(groups[0], last: top_count, range: period, time_zone: time_zone)
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.by_week')
          end
        end

        class ByMonth < DatetimeGroupByAttribute
          def group_order_limit(request, _order_arg, top_count, period)
            request.group_by_month(groups[0], last: top_count, range: period, time_zone: time_zone)
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.by_month')
          end
        end

        class HourOfDay < NumericGroupByAttribute
          def keys
            @keys ||= 0..23
          end

          def sortable
            false
          end

          def group_order_limit(request, _order_arg, _top_count, _period)
            request.group_by_hour_of_day(groups[0], time_zone: time_zone)
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.hour_of_day')
          end

          def time_zone
            nil
          end
        end

        class DayOfWeek < StringGroupByAttribute
          def keys
            @keys ||= (0..6).map { |d| (d + Date::DAYS_INTO_WEEK[Date.beginning_of_week] + 1) % 7 }
          end

          def sortable
            false
          end

          def group_order_limit(request, _order_arg, _top_count, _period)
            request.group_by_day_of_week(groups[0], time_zone: time_zone)
          end

          def label(key)
            I18n.t('date.day_names')[key]
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.day_of_week')
          end

          def time_zone
            nil
          end
        end
      end

      class DateGroupByAttribute < DatetimeGroupByAttribute
        protected

        def time_zone
          false
        end

        class ByWeek < DatetimeGroupByAttribute::ByWeek
          protected

          def time_zone
            false
          end
        end

        class ByMonth < DatetimeGroupByAttribute::ByMonth
          protected

          def time_zone
            false
          end
        end

        class DayOfWeek < DatetimeGroupByAttribute::DayOfWeek
          protected

          def time_zone
            false
          end
        end
      end

      class AggregateAttribute
        def initialize(name, definition)
          @name = name
          @definition = definition || name
        end
        attr_reader :name, :definition

        def human_name(klass)
          klass.human_attribute_name(name)
        end
      end

      class << self
        def group_by_attribute(name, type, **options, &block) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          sub_types = options.delete(:sub_types)

          name_classify = name.classify
          base_klass = const_get(:"#{type.to_s.classify}GroupByAttribute")
          if block_given?
            klass_name = :"Custom#{name_classify}GroupByAttribute"
            klass = Class.new(base_klass, &block)
            const_set(klass_name, klass)
          else
            klass = base_klass
          end
          group_by_attributes[name] = klass.new(name, **options)

          if sub_types # rubocop:disable Style/GuardClause
            sub_attribute_options = options.merge(sub_type: true)

            sub_types.each do |t|
              t_classify = t.to_s.classify

              sub_base_klass = base_klass.const_get(t_classify)
              if block_given?
                sub_klass_name = :"Custom#{name_classify}#{t_classify}GroupByAttribute"
                sub_klass = Class.new(sub_base_klass, &block)
                const_set(sub_klass_name, sub_klass)
              else
                sub_klass = sub_base_klass
              end

              group_by_attributes["#{name}_#{t}"] = sub_klass.new(name, **sub_attribute_options)
            end
          end
        end

        def aggregate_attribute(name, definition = nil)
          aggregate_attributes[name] = AggregateAttribute.new(name, definition)
        end

        def group_by_attributes
          @group_by_attributes ||= {}
        end

        def aggregate_attributes
          @aggregate_attributes ||= {}
        end

        def inherited(base)
          base.instance_variable_set(:@group_by_attributes, group_by_attributes.dup)
          base.instance_variable_set(:@aggregate_attributes, aggregate_attributes.dup)
          super
        end
      end

      def initialize(
        models,
        type:,
        group_by_attribute:,
        first:,
        top_count:,
        sort_by:,
        aggregate_operation:,
        aggregate_attribute:,
        display_percent:,
        period:
      )
        @models = models
        @type = type
        @group_by_attribute = self.class.group_by_attributes[group_by_attribute]
        @first = first
        @top_count = top_count
        @sort_by = sort_by
        @aggregate_operation = aggregate_operation
        @aggregate_attribute = self.class.aggregate_attributes[aggregate_attribute] if aggregate_attribute
        @display_percent = display_percent
        @period = period
      end
      attr_reader :models,
                  :type,
                  :group_by_attribute,
                  :first,
                  :top_count,
                  :sort_by,
                  :aggregate_operation,
                  :aggregate_attribute,
                  :display_percent,
                  :period

      def raw_data
        request = models
        request = joins(request)
        request = select(request)
        request = group_order_limit(request)
        aggregate(request)
      end

      def data
        return @data if @data

        data = raw_data
        data = compute_percent(data)
        @data = DataTransformer.new(self).transform(data)
      end

      def empty?
        data.all? { |_, v| v.zero? }
      end

      def to_chartkick(view_context, **options)
        new_options = {}
        new_options[:discrete] = true if group_by_attribute.discrete?
        if display_percent
          new_options[:suffix] = '%'
          new_options[:round] = 2
        end
        new_options[:height] = '600px'

        view_context.send("#{type}_chart", data, new_options.deep_merge(options))
      end

      private

      def joins(request)
        return request unless group_by_attribute.joins

        request.left_outer_joins(group_by_attribute.joins)
      end

      def select(request)
        return request unless group_by_attribute.selects

        request.select(*group_by_attribute.selects)
      end

      def group_order_limit(request)
        group_by_attribute.group_order_limit(request, order_arg(request), top_count, period)
      end

      def order_arg(request)
        asc_desc = first ? :asc : :desc

        order_arg = group_by_attribute.order_arg(request, asc_desc)
        order_arg = { order_aggregate_alias => asc_desc }.merge(order_arg) if sort_by == 'value'
        order_arg
      end

      def order_aggregate_alias
        if aggregate_operation == 'count'
          count_column_name
        else
          column_alias(aggregate_operation, aggregate_attribute.definition)
        end
      end

      def count_column_name
        :count_id
      end

      def column_alias(operation, sql_definition)
        models.send(:column_alias_for, "#{operation} #{sql_definition}")
      end

      def aggregate(request)
        if aggregate_operation == 'count'
          aggregate_count(request)
        else
          request.send(aggregate_operation, aggregate_attribute.definition)
        end
      end

      def aggregate_count(request)
        request.count(:id)
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

      class DataTransformer
        delegate :group_by_attribute, :sort_by, :first, to: :chart
        delegate :label?, :label, to: :group_by_attribute

        def initialize(chart)
          @chart = chart
        end
        attr_reader :chart

        # Adds missing keys, labels keys and sorts data.
        def transform(data)
          new_data = add_missing_keys(data)
          label_all(new_data)
        end

        private

        def add_missing_keys_with_value_sort?
          group_by_attribute.sortable && sort_by == 'value'
        end

        # A sort is needed after labelling if the attribute is sortable, we sort by label and either we label all keys
        # or we added non-sorted missing values.
        def label_keys_with_label_sort?
          group_by_attribute.sortable && sort_by == 'label' && (label? || group_by_attribute.keys)
        end

        # Adds missing keys specified by group_attribute.keys in data if any.
        # The keys of data are already sorted by the SQL request except if we sort by label and label? is true, in which
        # case a new sort will be necessary after labelling the keys.
        def add_missing_keys(data)
          if group_by_attribute.keys
            if add_missing_keys_with_value_sort?
              add_missing_keys_with_value_sort(data)
            else
              add_missing_keys_with_label_sort(data)
            end
          else
            data
          end
        end

        def add_missing_keys_with_value_sort(data)
          # The keys are already in the right order, so we just add the missing ones.
          missing_keys = group_by_attribute.keys_zero_data.except(*data.keys)
          if first
            missing_keys.merge(data)
          else
            data.merge(missing_keys)
          end
        end

        def add_missing_keys_with_label_sort(data)
          # For now, we just add the missing keys, #label_keys_with_label_sort will take care of sorting the keys.
          group_by_attribute.keys_zero_data.merge(data)
        end

        # Labels all keys of data and sort them again if necessary (if sort by "label").
        def label_all(data)
          if label_keys_with_label_sort?
            label_keys_with_label_sort(data)
          else
            label_keys_without_sort(data)
          end
        end

        # Labels all keys (if necessary) and sorts data.
        # The nil key "None" is placed last in ascending order and first in descending order.
        def label_keys_with_label_sort(data)
          # The idea is to extract the nil key, label and sort the other keys and add the nil key afterwards.

          nil_value = group_by_attribute.delete_and_return_nil_key!(data)

          new_data = if group_by_attribute.sortable == :before_label
                       sort_and_label_keys(data)
                     else # :after_label
                       label_and_sort_keys(data)
                     end

          sort_array_data_and_add_nil_value(new_data, nil_value)
        end

        def sort_and_label_keys(data)
          new_data = data.sort_by(&:first)
          if label?
            new_data.each do |d|
              d[0] = label(d[0])
            end
          end
          new_data
        end

        def label_and_sort_keys(data)
          new_data = data
          new_data = new_data.transform_keys { |k| label(k) } if label?
          new_data.sort_by(&:first)
        end

        def sort_array_data_and_add_nil_value(array_data, nil_value)
          # If first, we append nil key at the end (if present).
          # If not first, we reverse the sorted keys and start with the nil key (if present).

          if first
            new_data = array_data.to_h
            new_data[I18n.t('none')] = nil_value if nil_value
          else
            new_data = array_data.reverse.to_h
            new_data = { I18n.t('none') => nil_value }.merge(new_data) if nil_value
          end

          new_data
        end

        def label_keys_without_sort(data)
          data.transform_keys do |k|
            if group_by_attribute.nil_key?(k)
              I18n.t('none')
            elsif label?
              label(k)
            else
              k
            end
          end
        end
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
