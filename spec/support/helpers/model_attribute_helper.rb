module Support::ModelAttributeHelper
	def test_model_attributes
    ModelAttribute.all.each do |m|
      compliance_check = ComplianceCheck.new(control_attributes: { target: m.code })
      yield(m, compliance_check)
    end
  end

  def test_model_attributes_with_vitual_attributes
    ModelAttribute.all.each do |m|
      next unless m.options[:source_attributes].present?

      compliance_check = ComplianceCheck.new(control_attributes: { target: m.code })
      yield(m, compliance_check)
    end
  end

  def get_default_value model_attribute
    return "FF0000" if [:color, :text_color].include? model_attribute.name
    return "undefined" if model_attribute.name == :transport_submode
    return :outbound if model_attribute.name == :wayback

    if source_attributes = model_attribute.options[:source_attributes]
      return "FR" if source_attributes.include? :country_code
      return 12.3456 if source_attributes.include? :latitude
    end

    if model_attribute.options[:reference]
      klass_name = model_attribute.name

      if klass_name == :shape
        context = Chouette.create do
          shape
        end
        return context.shape
      end

      klass_name = :stop_area if klass_name == :parent || klass_name == :referent
      klass_name = :route if klass_name == :opposite_route
      return create(klass_name)
    end

    case data_type = model_attribute.data_type
    when :string then 'bus' #use this for now because of Chouette:Line transmoirt mode enumerize
    when :integer then 1
    when :float then 1.34
    when :date then Date.current
    else
      raise 'data type not supported', data_type
    end
  end
end
