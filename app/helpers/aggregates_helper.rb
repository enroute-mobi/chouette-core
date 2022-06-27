module AggregatesHelper
  def aggregate_status(aggregate)
    content_tag :span, '' do
      concat operation_status(aggregate.status)
      concat render_urgent_icon if aggregate.contains_urgent_offer?
    end
  end
end
