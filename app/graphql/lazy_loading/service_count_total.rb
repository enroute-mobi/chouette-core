module LazyLoading
  class ServiceCountTotal

    attr_reader :loader, :line_scope

    def initialize(query_context, line_id, from, to)
      @line_scope = LineScope.new line_id, from, to
      @loader = self.class.find_loader query_context

      loader.add line_scope
    end

    def service_count
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

        scopes.group_by { |scope| [ scope.from, scope.to ] }.each do |period, scopes|
          from, to = period
          line_ids = scopes.map(&:line_id)

          # For serviceCount
          line_values = @referential.service_counts.for_lines(line_ids).between(from, to).group(:line_id).sum(:count)

          line_values.each do |line_id, count|
            scope = scopes.find { |s| s.line_id == line_id }
            scope.value = count
          end

        end

        @loaded = true
      end

    end

  end
end
