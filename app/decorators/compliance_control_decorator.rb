class ComplianceControlDecorator < AF83::Decorator
  decorates ComplianceControl

  set_scope { object.compliance_control_set }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_class_method :predicate do
    object_class.predicate
  end

  define_instance_class_method :prerequisite do
    object_class.prerequisite
  end

  define_instance_class_method :dynamic_attributes do
    object_class.dynamic_attributes
  end

  define_instance_class_method :display_translated_subclass do
    I18n.t("compliance_controls.filters.subclasses.#{object.object_type}")
  end
end
