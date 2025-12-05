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
    attribute :subgroup_by_attribute, type: String
    attribute :subgroup_first, type: Boolean, default: true
    attribute :subgroup_top_count, type: Integer, default: 30

    attr_accessor :saved_name, :saved_description, :param_key

    enumerize :chart_type, in: %w[line pie column]
    enumerize :sort_by, in: %w[value label]
    enumerize :aggregate_operation, in: %w[count sum average]

    with_options if: :graphical? do
      validates :group_by_attribute, inclusion: { in: ->(r) { r.candidate_group_by_attributes } }
      validates :top_count, presence: true, numericality: { only_integer: true, greater_than: 1 }
      validates :sort_by, presence: true
      validates :aggregate_operation, presence: true
      validates :aggregate_attribute,
                inclusion: { in: ->(r) { r.candidate_aggregate_attributes } },
                if: :aggregate_attribute?
      with_options if: :chart_one_dimensional? do
        validates :subgroup_by_attribute, absence: true, if: :chart_one_dimensional?
      end
      with_options unless: :chart_one_dimensional? do
        validates :subgroup_by_attribute, inclusion: {
          in: ->(r) { r.candidate_group_by_attributes },
          allow_blank: true
        }
        validates :subgroup_top_count,
                  presence: true,
                  numericality: { only_integer: true, greater_than: 1 },
                  if: :subgroup_by_attribute
      end
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

      def attributes_from_params(params, **options)
        FromParamsBuilder.new(params, **options).attributes
      end

      def from_params(params, attributes = {})
        Rails.logger.debug "[Search] Raw params: #{params.inspect}"

        new(attributes).tap do |search|
          search.attributes = attributes_from_params(params, param_key: attributes[:param_key])
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
      errors.errors.each do |error|
        error.instance_variable_set(:@attribute, SAVED_SEARCH_ATTRIBUTE_MAPPING[error.attribute])
      end
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

      order.attributes = attributes.delete(:order) if attributes[:order]

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

    alias old_model_name model_name
    private :old_model_name
    def model_name
      if param_key
        @_model_name ||= old_model_name.dup.tap do |model_name|
          model_name.instance_variable_set(:@param_key, param_key.to_s)
        end
      else
        old_model_name
      end
    end

    # Create Search attributes from our legacy Controller params (:sort, :direction, :page, etc)
    class FromParamsBuilder
      def initialize(params = nil, **options)
        @params = params || {}
        @options = options
      end
      attr_reader :params, :options

      def attributes
        {}.tap do |attributes|
          attributes.merge! search_params

          attributes[:order] = { sort_attribute => sort_direction } if sort_attribute
          attributes[:page] = page
          attributes[:per_page] = per_page

          attributes.delete_if { |_, v| v.blank? }
        end
      end

      # TODO: :page, :per_page, :sort, :direction and :order should also consider a namespace
      def param_key
        options[:param_key] || :search
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
        (params[param_key] || {}).tap do |search_params|
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

    def chart_one_dimensional?
      chart_type == 'pie'
    end

    def search(scope)
      if valid?
        result = scope
        result = query(result).scope
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
        subgroup_by_attribute: subgroup_by_attribute,
        subgroup_first: subgroup_first,
        subgroup_top_count: subgroup_top_count,
        period: chart_period(group_by_attribute),
        subgroup_period: chart_period(subgroup_by_attribute)
      )
    end

    def chart_klass
      self.class.const_get(:Chart)
    end

    def chart_period(attribute)
      return nil unless attribute

      self.class.chart_periods[chart_klass.group_by_attributes[attribute].name]&.chart_period(self)
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

          def method_added(name) # rubocop:disable Metrics/MethodLength
            case name
            when :label_series
              define_method(:label_series?) do
                true
              end
            when :label
              define_method(:label?) do
                true
              end
              alias_method :label_series, :label unless method_defined?(:label_series)
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

        def label_series?
          false
        end

        def label?
          false
        end

        def discrete?
          true
        end

        def compute_xaxis_keys?
          sortable && discrete?
        end

        def select_length
          @select_length ||= selects ? selects.length : 1
        end

        def array?
          @array ||= select_length > 1
        end

        def keys_zero_data
          @keys_zero_data ||= keys.index_with(0).freeze
        end

        def keys_empty_hash_data
          @keys_empty_hash_data ||= keys.index_with({}.freeze).freeze
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

        def sql_quote(request, value)
          request.connection.quote(value)
        end

        # SQL expressions used to compute the value of each value of a key
        def sql_expressions(_models, _period)
          selects_from_options
        end

        # only used by attributes where #compute_xaxis_keys? is false
        def where_without_xaxis_keys(request, _top_count, _period)
          request
        end

        # simply group an attribute
        def group(request, _period)
          request.group(*selects_from_options)
        end

        # group an attribute for a series, we want a discrete list of all possible values
        def group_series(request, order_arg, top_count, period)
          group(request, period).order(order_arg).limit(top_count)
        end

        def group_order_limit(request, order_arg, top_count, period)
          group_series(request, order_arg, top_count, period)
        end

        protected

        def subtype_human_name
          nil
        end

        private

        def selects_from_options
          @selects_from_options ||= selects || [name]
        end
      end

      class StringGroupByAttribute < GroupByAttribute
      end

      class NumericGroupByAttribute < GroupByAttribute
        def discrete?
          keys
        end
      end

      module Groupdate
        def sql_expressions(models, period)
          [groupdate_adapter(models, period: period).group_clause]
        end

        def where_without_xaxis_keys(request, top_count, period)
          request.where(groupdate_adapter(request, top_count: top_count, period: period).send(:where_clause))
        end

        def group(request, period)
          request.group_by_period(
            groupdate_period,
            groupdate_column,
            **groupdate_magic_options(period: period, series: false)
          )
        end

        def group_order_limit(request, _order_arg, top_count, period)
          request.group_by_period(
            groupdate_period,
            groupdate_column,
            **groupdate_magic_options(top_count: top_count, period: period)
          )
        end

        protected

        def time_zone
          Time.zone
        end

        def time_zone_name
          time_zone == false ? 'Etc/UTC' : time_zone.tzinfo.name # see groupdate/magic
        end

        def groupdate_adapter(models, **options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          # copied from Groupdate::Magic::Relation.generate_relation

          magic = ::Groupdate::Magic::Relation.new(**groupdate_magic_options(**options).merge(period: groupdate_period))
          adapter_name = models.connection.adapter_name
          adapter = ::Groupdate.adapters[adapter_name]

          column = ::Groupdate::Magic::Relation.resolve_column(models.klass, groupdate_column)

          adapter.new(
            models,
            column: column,
            period: groupdate_period,
            time_zone: magic.time_zone,
            time_range: magic.time_range,
            week_start: magic.week_start,
            day_start: magic.day_start,
            n_seconds: magic.n_seconds
          )
        end

        def groupdate_column
          selects_from_options[0]
        end

        def groupdate_period
          raise NotImplementedError
        end

        def groupdate_magic_options(top_count: nil, period: nil, **options)
          {
            time_zone: time_zone,
            last: top_count,
            range: period
          }.merge(options)
        end
      end

      class DatetimeGroupByAttribute < GroupByAttribute
        include Groupdate

        def sortable
          :before_label
        end

        def label_series(key)
          I18n.l(key) # must match app/packs/src/charkick.js
        end

        def discrete?
          keys
        end

        protected

        def groupdate_period
          :day
        end

        class ByWeek < DatetimeGroupByAttribute
          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.by_week')
          end

          def groupdate_period
            :week
          end
        end

        class ByMonth < DatetimeGroupByAttribute
          def label_series(key)
            "#{I18n.t('date.month_names')[key.month]} #{key.year}" # must match app/packs/src/charkick.js
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.by_month')
          end

          def groupdate_period
            :month
          end
        end

        class HourOfDay < NumericGroupByAttribute
          include Groupdate

          def keys
            @keys ||= 0..23
          end

          def sortable
            false
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.hour_of_day')
          end

          def groupdate_period
            :hour_of_day
          end

          def groupdate_magic_options(top_count: nil, period: nil, **options) # rubocop:disable Lint/UnusedMethodArgument
            super(**options)
          end
        end

        class DayOfWeek < StringGroupByAttribute
          include Groupdate

          def keys
            @keys ||= (0..6).map { |d| (d + Date::DAYS_INTO_WEEK[Date.beginning_of_week]) % 7 }
          end

          def sortable
            false
          end

          def label(key)
            I18n.t('date.day_names')[key]
          end

          protected

          def subtype_human_name
            I18n.t('activemodel.attributes.search.chart.group_by_attribute.sub_type.day_of_week')
          end

          def groupdate_period
            :day_of_week
          end

          def groupdate_magic_options(top_count: nil, period: nil, **options) # rubocop:disable Lint/UnusedMethodArgument
            super(**options)
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

      def initialize( # rubocop:disable Metrics/MethodLength
        models,
        type:,
        group_by_attribute:,
        first:,
        top_count:,
        sort_by:,
        aggregate_operation:,
        aggregate_attribute:,
        display_percent:,
        subgroup_by_attribute:,
        subgroup_first:,
        subgroup_top_count:,
        period:,
        subgroup_period:
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
        @subgroup_by_attribute = self.class.group_by_attributes[subgroup_by_attribute] if subgroup_by_attribute
        @subgroup_first = subgroup_first
        @subgroup_top_count = subgroup_top_count
        @period = period
        @subgroup_period = subgroup_period
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
                  :subgroup_by_attribute,
                  :subgroup_first,
                  :subgroup_top_count,
                  :period,
                  :subgroup_period

      def xaxis_dimension
        @xaxis_dimension ||= XaxisDimension.new(self)
      end

      def series_dimension
        @series_dimension ||= SeriesDimension.new(self)
      end

      def xaxis
        @xaxis ||= if sort_by == 'label'
                     XaxisSortedByLabelRequestBuilder.new(self).execute
                   else
                     XaxisSortedByValueRequestBuilder.new(self).execute
                   end
      end

      def series
        @series ||= if sort_by == 'label'
                      SeriesSortedByLabelRequestBuilder.new(self).execute
                    else
                      SeriesSortedByValueRequestBuilder.new(self).execute
                    end
      end

      def raw_data
        RawDataRequestBuilder.new(self).execute
      end

      def data
        return @data if @data

        data = raw_data
        data = compute_percent(data)

        @data ||= if subgroup_by_attribute
                    data = extract_series(data)
                    data = transform_series(data)
                    format_as_series(data)
                  else
                    transform_data(data)
                  end
      end

      def empty?
        if subgroup_by_attribute
          data.all? { |d| series_data_empty?(d[:data]) }
        else
          series_data_empty?(data)
        end
      end

      def to_chartkick(view_context, **options)
        new_options = {}
        new_options[:discrete] = true if group_by_attribute.discrete?
        if display_percent
          new_options[:suffix] = '%'
          new_options[:round] = 2
        end
        new_options[:height] = '600px'
        new_options[:stacked] = true if type == 'column'

        view_context.send("#{type}_chart", data, **new_options.deep_merge(options))
      end

      # used by RequestBuilder

      def count_column_name
        :count_id
      end

      def column_alias_for_operation(operation, sql_definition)
        column_alias_for("#{operation} #{sql_definition.downcase}")
      end

      def column_alias_for(field)
        column_alias_tracker.send(:column_alias_for, field)
      end

      def aggregate_count(request)
        request.count(:id)
      end

      private

      def series_data_empty?(series_data)
        series_data.all? { |_, v| v.nil? || v.zero? }
      end

      def compute_percent(result)
        return result unless display_percent

        sum = result.values.compact.sum
        if sum.zero?
          result.transform_values { 0 }
        else
          result.transform_values { |v| v.nil? ? 0 : v * 100.0 / sum }
        end
      end

      def extract_series(data) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
        result = {}
        xaxis_keys_without_value = xaxis.to_set if group_by_attribute.compute_xaxis_keys?

        data.each do |d|
          series_id = if subgroup_by_attribute.array?
                        d[0].take(subgroup_by_attribute.select_length)
                      else
                        d[0][0]
                      end
          xaxis_id = if group_by_attribute.array?
                       d[0].drop(subgroup_by_attribute.select_length)
                     else
                       d[0][-1]
                     end

          result[series_id] ||= {}
          result[series_id][xaxis_id] = d[1]

          xaxis_keys_without_value.delete(xaxis_id) if group_by_attribute.compute_xaxis_keys?
        end

        if group_by_attribute.compute_xaxis_keys?
          xaxis_zero_data = xaxis.index_with(0)
          xaxis_zero_data = xaxis_zero_data.except(*xaxis_keys_without_value) if xaxis_keys_without_value.any?

          result.transform_values! do |series_data|
            xaxis_zero_data.merge(series_data)
          end
        end

        result
      end

      def transform_series(data)
        data = data.transform_values do |series_data|
          transform_data(series_data)
        end
        series_dimension.transform(data)
      end

      def format_as_series(data)
        data.map do |series_id, series_data|
          { name: series_id, data: series_data }
        end
      end

      def transform_data(data)
        xaxis_dimension.transform(data)
      end

      def column_alias_tracker
        @column_alias_tracker ||= ::ActiveRecord::Calculations::ColumnAliasTracker.new(models.connection)
      end

      # An attribute within a chart with its dedicated parameters (top_count, first, period).
      class Dimension
        def initialize(chart)
          @chart = chart
        end
        attr_reader :chart

        # Context of the attribute within the chart.

        def attribute
          raise NotImplementedError
        end

        def top_count
          raise NotImplementedError
        end

        def first
          raise NotImplementedError
        end

        def period
          raise NotImplementedError
        end

        # Methods to build the dimension request.

        def sql_expressions
          @sql_expressions ||= attribute.sql_expressions(chart.models, period).freeze
        end

        # the aliases of the group clauses to be used in ORDER
        def sql_aliases
          @sql_aliases ||= sql_expressions.map { |hc| chart.column_alias_for(hc.downcase) }.freeze
        end

        def where(request) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          if keys.empty?
            request.none
          else
            where = keys.map do |d|
              if attribute.array?
                sql_expressions.zip(d).map do |c, v|
                  where_sql_expression_equals_key_part(c, v)
                end.join(' AND ')
              else
                # NOTE: this could be written with a IN () if d is never NULL
                sql_expressions.map { |c| where_sql_expression_equals_key_part(c, d) }
              end
            end.join(') OR (')
            request.where("(#{where})")
          end
        end

        def group(request)
          attribute.group(request, period)
        end

        def group_series(request, order_arg)
          attribute.group_series(request, order_arg, top_count, period)
        end

        def order_arg
          @order_arg ||= sql_aliases.index_with(asc_desc).freeze
        end

        def asc_desc
          first ? :asc : :desc
        end

        # Adds missing keys, labels keys and sorts data.
        def transform(data)
          new_data = add_missing_keys(data)
          label_all(new_data)
        end

        protected

        def keys
          raise NotImplementedError
        end

        def label?
          raise NotImplementedError
        end

        def label(key)
          raise NotImplementedError
        end

        def attribute_keys_empty_data
          raise NotImplementedError
        end

        private

        def where_sql_expression_equals_key_part(sql_expression, key_part)
          if key_part.nil?
            "#{sql_expression} IS NULL"
          else
            "#{sql_expression} = #{attribute.sql_quote(chart.models, key_part)}"
          end
        end

        def label_keys_with_label_sort?
          attribute.sortable
        end

        # Adds missing keys specified by attribute.keys in data if any.
        def add_missing_keys(data)
          if attribute.keys
            merge_attribute_keys_empty_data_with_data(data)
          else
            data
          end
        end

        def merge_attribute_keys_empty_data_with_data(data)
          attribute_keys_empty_data.merge(data)
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

          nil_value = attribute.delete_and_return_nil_key!(data)

          new_data = if attribute.sortable == :before_label
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
            if attribute.nil_key?(k)
              I18n.t('none')
            elsif label?
              label(k)
            else
              k
            end
          end
        end
      end

      class XaxisDimension < Dimension
        delegate :top_count, :first, :period, :sort_by, to: :chart
        delegate :compute_xaxis_keys?, :label?, :label, to: :attribute

        protected :label?, :label # rubocop:disable Style/AccessModifierDeclarations # TODO: rubocop bug
        private :sort_by

        def attribute
          chart.group_by_attribute
        end

        def where(request)
          if compute_xaxis_keys?
            super
          else
            attribute.where_without_xaxis_keys(request, top_count, period)
          end
        end

        def order_arg
          @order_arg ||= compute_xaxis_keys? ? super : {}.freeze
        end

        protected

        def keys
          chart.xaxis
        end

        def attribute_keys_empty_data
          attribute.keys_zero_data
        end

        private

        # A sort is needed after labelling if the attribute is sortable, we sort by label and either we label all keys
        # or we added non-sorted missing values.
        def label_keys_with_label_sort?
          super && sort_by == 'label' && (label? || attribute.keys)
        end

        def add_missing_keys_with_value_sort?
          attribute.sortable && sort_by == 'value'
        end

        # The keys of data are already sorted by the SQL request except if we sort by label and label? is true, in which
        # case a new sort will be necessary after labelling the keys.
        def merge_attribute_keys_empty_data_with_data(data)
          if add_missing_keys_with_value_sort?
            add_missing_keys_with_value_sort(data)
          else
            # For now, we just add the missing keys, #label_keys_with_label_sort will take care of sorting the keys.
            super
          end
        end

        def add_missing_keys_with_value_sort(data)
          # The keys are already in the right order, so we just add the missing ones.
          missing_keys = attribute_keys_empty_data.except(*data.keys)
          if first
            missing_keys.merge(data)
          else
            data.merge(missing_keys)
          end
        end
      end

      class SeriesDimension < Dimension
        def attribute
          chart.subgroup_by_attribute
        end

        def top_count
          chart.subgroup_top_count
        end

        def first
          chart.subgroup_first
        end

        def period
          chart.subgroup_period
        end

        protected

        def keys
          chart.series
        end

        def label?
          attribute.label_series?
        end

        def label(key)
          attribute.label_series(key)
        end

        def attribute_keys_empty_data
          attribute.keys_empty_hash_data
        end
      end

      class RequestBuilder
        def initialize(chart)
          @chart = chart
          @request = models
        end
        attr_reader :chart

        delegate :models,
                 :xaxis_dimension,
                 :series_dimension,
                 :aggregate_operation,
                 :aggregate_attribute,
                 :count_column_name,
                 :column_alias_for_operation,
                 :aggregate_count,
                 to: :chart

        def build!
          raise NotImplementedError
        end

        def execute
          build!
        end

        private

        def joins(dimension)
          return unless dimension.attribute.joins

          @request = @request.left_outer_joins(dimension.attribute.joins)
        end

        def select(dimension)
          return unless dimension.attribute.selects

          @request = @request.select(*dimension.attribute.selects)
        end

        # Calling #aggregate automatically adds a "AS" to each column. We have to do it manually.
        def select_with_alias(dimension)
          @request = @request.select(
            *dimension.sql_expressions.zip(dimension.sql_aliases).map { |s, a| "#{s} AS #{a}" }
          )
        end

        def where(dimension)
          @request = dimension.where(@request)
        end

        def group_series(dimension, order_arg)
          @request = dimension.group_series(@request, order_arg)
        end

        def sort_by_value_order_arg(dimension)
          { order_aggregate_alias => xaxis_dimension.asc_desc }.merge(dimension.order_arg)
        end

        def order_aggregate_alias
          if aggregate_operation == 'count'
            count_column_name
          else
            column_alias_for_operation(aggregate_operation, aggregate_attribute.definition)
          end
        end

        def aggregate
          if aggregate_operation == 'count'
            aggregate_count(@request)
          else
            @request.send(aggregate_operation, aggregate_attribute.definition)
          end
        end

        def select_values(dimension)
          if dimension.attribute.array?
            models.connection.select_rows(@request)
          else
            models.connection.select_values(@request)
          end
        end
      end

      # Builds the request for x-xaxis when the chart is sorted by label.
      # We need to get the top_count first/last ticks of each dimension sorted by alphabetical order.
      class XaxisSortedByLabelRequestBuilder < RequestBuilder
        def build!
          joins(xaxis_dimension)
          select_with_alias(xaxis_dimension)
          group_series(xaxis_dimension, xaxis_dimension.order_arg)
        end

        def execute
          super
          select_values(xaxis_dimension)
        end
      end

      # Builds the request for x-axis when the chart is sorted by value.
      # The request is similar to the building of a chart without subgroup. We just only select discrete ticks.
      class XaxisSortedByValueRequestBuilder < RequestBuilder
        def build!
          joins(xaxis_dimension)
          select(xaxis_dimension)
          group_series(xaxis_dimension, sort_by_value_order_arg(xaxis_dimension))
        end

        def execute
          super
          aggregate.keys
        end
      end

      # Builds the request for series when the chart is sorted by label.
      # The request is similar to x-axis except that we we filter on the previously computed x-axis ticks.
      class SeriesSortedByLabelRequestBuilder < RequestBuilder
        def build!
          joins(series_dimension)
          select_with_alias(series_dimension)
          joins(xaxis_dimension)
          where(xaxis_dimension)
          group_series(series_dimension, series_dimension.order_arg)
        end

        def execute
          super
          select_values(series_dimension)
        end
      end

      # Builds the request for series when the chart is sorted by value.
      # The request is similar to x-axis except that we we filter on the previously computed x-axis ticks.
      class SeriesSortedByValueRequestBuilder < RequestBuilder
        def build!
          joins(series_dimension)
          select(series_dimension)
          joins(xaxis_dimension)
          where(xaxis_dimension)
          group_series(series_dimension, sort_by_value_order_arg(series_dimension))
        end

        def execute
          super
          aggregate.keys
        end
      end

      class RawDataRequestBuilder < RequestBuilder
        delegate :sort_by,
                 :subgroup_by_attribute,
                 to: :chart

        def build! # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          if subgroup_by_attribute
            joins(series_dimension)
            select(series_dimension)
          end
          joins(xaxis_dimension)
          select(xaxis_dimension)
          if subgroup_by_attribute
            where(series_dimension)
            where(xaxis_dimension) if xaxis_dimension.compute_xaxis_keys? # already added by #group_order_limit
          end
          group(series_dimension) if subgroup_by_attribute
          group_order_limit
        end

        def execute
          super
          aggregate
        end

        private

        def group(dimension)
          @request = dimension.group(@request)
        end

        def group_order_limit
          @request = xaxis_dimension.attribute.group_order_limit(@request, order_arg, top_count, xaxis_dimension.period)
        end

        def order_arg
          order_arg = xaxis_order_arg
          order_arg = order_arg.merge(series_dimension.order_arg) if subgroup_by_attribute
          order_arg
        end

        def xaxis_order_arg
          if sort_by == 'label'
            xaxis_dimension.order_arg
          else
            sort_by_value_order_arg(xaxis_dimension)
          end
        end

        def top_count
          top_count = xaxis_dimension.top_count
          top_count *= series_dimension.top_count if subgroup_by_attribute
          top_count
        end
      end
    end

    private

    def aggregate_attribute?
      aggregate_operation.in?(%w[sum average])
    end
  end

  class Order
    def initialize(attributes = nil)
      self.attributes = attributes || self.class.defaults
    end

    def attributes
      self.class.attributes.filter_map do |attribute|
        attribute_value = send(attribute.name)
        next nil unless attribute_value

        [attribute.name, attribute_value]
      end.to_h
    end

    def attributes=(attributes = {})
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)

      self.class.attributes.each do |attribute|
        attribute_value = attributes[attribute.name]
        send("#{attribute.name}=", attribute_value || nil)
      end
    end

    def order_hash
      self.class.attributes.filter_map do |attribute|
        attribute_value = send(attribute.name)
        next nil unless attribute_value

        [attribute.column, attribute_value]
      end.to_h
    end

    def order(scope)
      scope = self.class.attributes.inject(scope) do |s, attribute|
        next s unless attribute.joins
        next s unless send(attribute.name)

        s.joins(attribute.joins)
      end
      scope.order(order_hash)
    end

    class << self
      def attributes
        @attributes ||= []
      end

      def defaults
        @defaults ||= attributes.filter_map do |attribute|
          next nil unless attribute.default?

          [attribute.name, attribute.default]
        end.to_h
      end

      # TODO: Attributes can only return values :asc, :desc or nil (for security reason)
      # Attributes can be set with "asc", :asc, 1 to have the :asc value
      # Attributes can be set with "desc", :desc, -1 to have the :desc value
      # Attributes can be set with nil, 0 to have the nil value
      #
      # These methods ensures that the sort attribute is supported and valid
      def attribute(name, options = {})
        attribute = Attribute.new(name, options)

        define_method "#{name}=" do |value|
          value = attribute.order(value)
          instance_variable_set "@#{name}", value
        end
        attr_reader name

        attributes << attribute
      end

      def inherited(base)
        base.instance_variable_set(:@attributes, attributes.deep_dup)
        super
      end
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
      attr_writer :column
      attr_accessor :joins, :default

      def column
        @column ||= name
      end

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
