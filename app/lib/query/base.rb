module Query
  class Base
    def initialize(scope)
      @scope = scope
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
