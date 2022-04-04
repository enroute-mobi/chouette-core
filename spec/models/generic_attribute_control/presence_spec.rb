RSpec.describe GenericAttributeControl::Presence, type: :model, scope: :model_attribute do
  include Support::ModelAttributeHelper

  let( :default_code ){ "3-Generic-2" }
  let( :factory ){ :generic_attribute_control_presence }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
  it_behaves_like 'has target attribute'
  it_behaves_like 'GenericAttributeControl::InternalBaseInterface'

  describe '#compliance_test' do
    context 'when attribute is present' do
      it 'should be compliant' do
        test_model_attributes do |m, compliance_check|
          instance = m.klass.new
          unless virtual_attributes[m.code]
            instance.send("#{m.name}=", get_default_value(m))
          else
            instance.send("country_code=", "FR")
          end
          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_truthy
        end
      end
    end

    context 'when attribute is absent' do
      it 'should not be compliant' do
        test_model_attributes do |m, compliance_check|
          instance = m.klass.new
          instance.send("#{m.name}=", nil) unless virtual_attributes[m.code]

          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_falsey
        end
      end
    end
  end
end
