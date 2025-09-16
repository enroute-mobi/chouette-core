module Query
  class Base
    def initialize(scope)
      @scope = scope
      # TODO: CHOUETTE-4721 (rails 7.2): we may have to simply do scope.order(order_hash) in Search::Base
      scope_to_extend = if @scope.is_a?(::ActiveRecord::Associations::CollectionProxy)
                          @scope.proxy_association.scope
                        else
                          @scope
                        end
      @scope = scope_to_extend.extend(self.class::CustomJoins) if self.class::CustomJoins != ::Query::Base::CustomJoins
    end

    module CustomJoins
      def joins
        @joins ||= {}
      end

      def define(name, definition)
        joins[name] = definition
      end

      private

      def extend_object(base)
        base.extend(Scope)
        base.instance_variable_set(:@custom_joins_parent, self)

        super
      end

      module Scope
        def joins(*args)
          if args.is_a?(Array) && args.all? { |a| a.is_a?(Symbol) }
            super(args.map { |arg| @custom_joins_parent.joins[arg] || arg })
          else
            super
          end
        end
      end
    end

    attr_reader :scope

    def where(raw_value, predicate, *columns)
      change_scope(if: value_present?(raw_value)) do |scope|
        value = serialize_value(raw_value, predicate)
			  get_clause = Proc.new { |c| scope.arel_table[c.to_sym].send(predicate, value) }

			  where_clause = columns[1..]
				                 .reduce(get_clause.call(columns[0])) do |clause, column|
					clause.or(get_clause.call(column))
				end

        scope.where where_clause
      end
    end

    protected

    attr_writer :scope

    private

    def serialize_value(value, predicate)
			return "%#{value}%" if predicate == :matches

			value
    end

    def change_scope(options = {}, &block)
      unless options.has_key?(:if) && !options[:if]
        self.scope = block.call(scope)
      end

      self
    end

    ARRAY_WITH_EMPTY_STRING = [''].freeze
    def value_present?(value)
      value.present? && value != ARRAY_WITH_EMPTY_STRING
    end
  end
end
