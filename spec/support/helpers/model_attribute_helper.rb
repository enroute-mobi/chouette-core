module Support::ModelAttributeHelper
	def test_model_attributes
    ModelAttribute.all.each do |m|
      compliance_check = ComplianceCheck.new(control_attributes: { target: m.code })
      yield(m, compliance_check)
    end
  end

  def get_default_value model_attribute
    case data_type = model_attribute.data_type
    when :string then 'bus' #use this for now because of Chouette:Line transmoirt mode enumerize
    when :integer then 1
    when :float then 1.34
    else
      raise 'data type not supported', data_type
    end
  end
end
