# Find LinePeriods (line & period) provided by the
# Referential source which are also in the Referential target
#
# When a priority is given, only metadatas with a lower priorities in
# the target Referential are analysed
class ReferentialOverlaps
  def initialize(source, target, attributes = {})
    @source, @target = source, target
    attributes.each { |k,v| send "#{k}=", v }
  end
  attr_reader :source, :target
  attr_accessor :priority

  def overlapping_periods
    @query ||= Query.new(source, target, max_priority: priority)
  end

  class Query
    include Enumerable

    def initialize(source, target, max_priority: nil)
      @source, @target, @max_priority = source, target, max_priority
    end
    attr_reader :source, :target, :max_priority

    def all
      @all ||= to_rows.map { |row| Referential::LinePeriod.new row }
    end

    delegate :each, :empty?, :inspect, to: :all

    def to_rows
      ActiveRecord::Base.connection.select_all to_sql
    end

    def to_sql
      """
      select source.line_id as line_id, target.period * source.period as period
        from (#{source_line_periods.to_sql}) as source
        join (#{target_line_periods.to_sql}) as target
        on source.line_id = target.line_id and target.period && source.period;
      """.strip
    end

    def source_line_periods
      source.line_periods
    end

    def target_line_periods
      target.line_periods max_priority: max_priority
    end

  end


end
