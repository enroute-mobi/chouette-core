module AggregatesHelper
  def aggregate_status(aggregate)
    content_tag :span, '' do
      concat operation_status(aggregate.status)
      concat render_urgent_icon if aggregate.contains_urgent_offer?
    end
  end

  def decorated_duration(duration)
    Aggregate::Resource.tmf(:duration_value, count: duration)
  end

  def decorated_metrics(metrics)
    Metrics.new(metrics).decorated_metrics
  end

  class Metrics
    def initialize(metrics)
      @metrics = metrics
    end

    attr_reader :metrics

    def decorated_metrics
      [ decorated_vehicle_journey_count, decorated_overlapping_period_count ].compact.join(', ')
    end

    def decorated_vehicle_journey_count
      return unless metrics['vehicle_journey_count'] > 0

      Aggregate::Resource.tmf(:vehicle_journey_count, count: metrics['vehicle_journey_count'])
    end

    def decorated_overlapping_period_count
      return unless metrics['overlapping_period_count'] > 0

      Aggregate::Resource.tmf(:overlapping_period_count, count: metrics['overlapping_period_count'])
    end
  end
end
