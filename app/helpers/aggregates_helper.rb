module AggregatesHelper
  def aggregate_status(aggregate)
    content_tag :span, '' do
      concat operation_status(aggregate.status)
      concat render_urgent_icon if aggregate.contains_urgent_offer?
    end
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
      [ vehicle_journey_count, overlapping_period_count ].compact.join(', ')
    end

    def vehicle_journey_count
      return unless metrics['vehicle_journey_count'] > 0

      [
        metrics['vehicle_journey_count'],
        Aggregate::Resource.tmf(metrics['vehicle_journey_count'] == 1 ? :vehicle_journey : :vehicle_journeys)
      ].join(' ')
    end

    def overlapping_period_count
      return unless metrics['overlapping_period_count'] > 0

      [
        metrics['overlapping_period_count'],
        Aggregate::Resource.tmf(metrics['overlapping_period_count'] == 1 ? :cleaned_period : :cleaned_periods)
      ].join(' ')
    end
  end
end
