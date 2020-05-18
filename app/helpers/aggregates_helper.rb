module AggregatesHelper
  def aggregate_metadatas(aggregate)
    {
      Aggregate.tmf(:referentials) => aggregate.referentials.map{ |r| link_to(decorate_referential_name(r), referential_path(r)) }.join(', ').html_safe,
      Aggregate.tmf(:status) => operation_status(aggregate.status, verbose: true, i18n_prefix: "aggregates.statuses"),
      Aggregate.tmf(:new) => aggregate.new ? link_to(aggregate.new.name, referential_path(aggregate.new)) : '-',
      Aggregate.tmf(:contains_urgent_offer) => boolean_icon(aggregate.contains_urgent_offer?)
    }
  end

  def aggregate_status(aggregate)
    content_tag :span, '' do
      concat operation_status(aggregate.status)
      concat render_urgent_icon if aggregate.contains_urgent_offer?
    end
  end
end
