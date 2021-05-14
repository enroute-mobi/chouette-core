RSpec.shared_examples_for 'GenericAttributeControl::InternalBaseInterface' do
	include Support::ModelAttributeHelper

	describe '#collection_type' do
		it 'should return the right collection_type' do
			test_model_attributes do |m, compliance_check|
				expected_collection_type = m.klass.to_s.pluralize.to_sym

				expect(described_class.collection_type(compliance_check)).to eq(expected_collection_type)
			end
		end
	end
end
