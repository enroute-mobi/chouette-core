
RSpec.describe GenericAttributeControl::Presence, type: :model do
  let( :default_code ){ "3-Generic-4" }
  let( :factory ){ :generic_attribute_control_presence }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
  it_behaves_like 'has target attribute'

  describe '#compliance_test' do
    context 'when attribute is present' do
      it 'should be compliant' do
        ModelAttribute.all.each do |m|
          target = "#{m.klass}##{m.name}"
          instance = m.class_name.new
          instance.send("#{m.name}=", get_default_value(m.data_type))
          compliance_check = ComplianceCheck.new(control_attributes: { target: target })

          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_truthy
        end
      end
    end

    context 'when attribute is absent' do
      it 'should not be compliant' do
        ModelAttribute.all.each do |m|
          target = "#{m.klass}##{m.name}"
          instance = m.class_name.new
          instance.send("#{m.name}=", nil)

          compliance_check = ComplianceCheck.new(control_attributes: { target: target })

          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_falsey
        end
      end
    end
  end

  def get_default_value data_type
    case data_type
    when :string then 'bus' #use this for now because of Chouette:Line transmoirt mode enumerize
    when :integer then 1
    when :float then 1.34
    else
      raise 'data type not supported', data_type
    end
  end
end
