module Query
  class Base
    def initialize(scope)
      @scope = scope
    end
    attr_reader :scope

    def where(raw_value, predicate, *columns)
      return self if raw_value.blank?

      value = serialize_value(raw_value, predicate)
			get_clause = Proc.new { |c| scope.arel_table[c.to_sym].send(predicate, value) }

			where_clause = columns[1..]
				.reduce(get_clause.call(columns[0])) do |clause, column|
					clause.or(get_clause.call(column))
				end

      self.scope = scope.where where_clause

			self
    end

    protected

    attr_writer :scope

    private

    def serialize_value(value, predicate)
			return "%#{value}%" if predicate == :matches

			value
		end
  end
end
