class PurchaseWindowDecorator < AF83::Decorator
  decorates Chouette::PurchaseWindow

  set_scope { context[:referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :bounding_dates do
    unless object.date_ranges.empty?
      object.date_ranges.map(&:min).min..object.date_ranges.map(&:max).max
    end
  end

end
