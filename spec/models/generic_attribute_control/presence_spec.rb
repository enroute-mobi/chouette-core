RSpec.describe GenericAttributeControl::Presence, type: :model, scope: :model_attribute do
  include Support::ModelAttributeHelper

  let( :default_code ){ "3-Generic-4" }
  let( :factory ){ :generic_attribute_control_presence }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
  it_behaves_like 'has target attribute'
  it_behaves_like 'GenericAttributeControl::InternalBaseInterface'

  describe '#compliance_test' do
    context 'when attribute is present' do
      it 'should be compliant' do
        test_model_attributes do |m, compliance_check|
          instance = m.class_name.new
          instance.send("#{m.name}=", get_default_value(m))

          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_truthy
        end
      end
    end

    context 'when attribute is absent' do
      it 'should not be compliant' do
        test_model_attributes do |m, compliance_check|
          target = "#{m.klass}##{m.name}"
          instance = m.class_name.new
          instance.send("#{m.name}=", nil)

          compliant = GenericAttributeControl::Presence.compliance_test(compliance_check, instance)

          expect(compliant).to be_falsey
        end
      end
    end
  end
end
