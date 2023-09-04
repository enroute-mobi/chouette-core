module ComplianceControlsHelper
  def subclass_selection_list
    compliance_control_types_options.keys.map(&method(:make_subclass_selection_item))
  end

  def make_subclass_selection_item(key)
    
    [t("compliance_controls.filters.subclasses.#{key}"), "-#{key.camelcase}-"]
  end

  def display_control_attribute(key, value, compliance_control)
    compliance_control = compliance_control.object if compliance_control.respond_to?(:object)
    if key == "target"
      parts = value.match(%r((?'object_type'\w+)#(?'attribute'\w+)))
      object_type = "activerecord.models.#{parts[:object_type]}".t(count: 1).capitalize
      target = I18n.t("activerecord.attributes.#{parts[:object_type]}.#{parts[:attribute]}")
      "#{object_type} - #{target}"
    elsif key == "custom_field_code"
      cf = compliance_control.class.custom_field(compliance_control)
      "#{cf.resource_class.ts.capitalize} | #{cf.name}"
    else
      value
    end.html_safe
  end

  def compliance_control_metadatas(compliance_control)
    attributes = resource.class.dynamic_attributes
    attributes.push(*resource.control_attributes.keys) if resource&.control_attributes&.keys

    {}.tap do |hash|
      attributes.each do |attribute|
        hash[ComplianceControl.human_attribute_name(attribute)] = display_control_attribute(attribute, resource.send(attribute), compliance_control)
      end
    end
  end

  def compliance_control_types_options
    ComplianceControl.descendants.group_by(&:object_type)
  end

  def compliance_control_target_options(cc)
    list = ModelAttribute.all.reject(&:mandatory) if cc.is_a? GenericAttributeControl::Presence

    ModelAttribute.grouped_options(list: list, type: cc.class.attribute_type)
  end
end
