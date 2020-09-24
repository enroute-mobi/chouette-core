module LazyLoading
  class ServiceCounts

    attr_reader :loader, :line_scope

    def initialize(query_context, line_id, from, to)
      @line_scope = LineScope.new line_id, from, to
      @loader = self.class.find_loader query_context

      loader.add line_scope
    end

    def service_counts
      loader.load
      line_scope.value
    end

    def self.find_loader(query_context)
      query_context[:lazy_find_line_service_counts_loader] ||=
        begin
          referential = query_context[:target_referential]
          Loader.new referential
        end
    end

    class LineScope

      def initialize(line_id, from, to)
        @line_id, @from, @to = line_id, from&.to_date, to&.to_date
      end

      attr_reader :line_id, :from, :to
      attr_accessor :value

    end

    class Loader

      def initialize(referential)
        @referential = referential
      end

      def add(scope)
        scopes << scope
      end

      def scopes
        @scopes ||= []
      end

      def load
        return if @loaded
        scopes.group_by { |scope| [ scope.from, scope.to ] }.each do |period, period_scopes|
          from, to = period
          line_ids = period_scopes.map(&:line_id)

          line_values = @referential.service_counts.for_lines(line_ids).between(from, to).where.not(count: 0).
                          group(:line_id, :date).having("sum(count) > 0").order(:date).sum(:count)

          line_values.each do |(line_id, date), count|
            scope = period_scopes.find { |s| s.line_id == line_id }
            scope.value << { date: date, count: count }
          end
        end

        @loaded = true
      end

    end

  end
end
