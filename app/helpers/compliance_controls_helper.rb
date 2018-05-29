module ComplianceControlsHelper
  def subclass_selection_list
    ComplianceControl.subclass_patterns.map(&method(:make_subclass_selection_item))
  end


  def make_subclass_selection_item(key_pattern)
    key, pattern = key_pattern
    [t("compliance_controls.filters.subclasses.#{key}"), "-#{pattern}-"]
  end

  def display_control_attribute(key, value)
    if key == "target"
      parts = value.match(%r((?'object_type'\w+)#(?'attribute'\w+)))
      object_type = ComplianceControl.tmf("subclasses.#{parts[:object_type]}")
      target = I18n.t("activerecord.attributes.#{parts[:object_type]}.#{parts[:attribute]}")
      "#{object_type} - #{target}"
    else
      value
    end 
  end

  def compliance_control_metadatas(compliance_control)
    attributes = resource.class.dynamic_attributes
    attributes.push(*resource.control_attributes.keys) if resource&.control_attributes&.keys

    {}.tap do |hash|
      attributes.each do |attribute|
        hash[ComplianceControl.human_attribute_name(attribute)] = display_control_attribute(attribute, resource.send(attribute))
      end
    end
  end
end
