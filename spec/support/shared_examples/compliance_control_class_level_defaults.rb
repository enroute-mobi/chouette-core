require_relative '../data_modifier'

H = Support::DataModifier::Hash
RSpec.shared_examples_for 'ComplianceControl Class Level Defaults' do
    context 'class attributes' do
      it 'are correctly set' do
        expect( described_class.default_code).to eq(default_code)
      end
    end
    context 'are used in instantiation' do
      let( :record ){ create factory }
      let( :default_att_names ){%w[ code origin_code ]}

      it 'all defaults' do
        expect( record.attributes.values_at(*default_att_names ))
          .to eq([ default_code, default_code])
      end
      it 'but provided values are not overwritten by defaults' do
        code        = random_string
        origin_code = random_string
        # Remove each of the attributes from explicit initialisation to see
        # its value provided by CCCWDA.

        # atts :: Map(String, (explicit_value, default_value))
        atts = {
          'code'        => [code, default_code],
          'origin_code' => [origin_code, default_code],
        }
        atts.keys.each do |key|
          # Replace key to be tested by default value
          expected = H.first_values(atts).merge(key => atts[key].last)
          expected_values = expected.values_at(*default_att_names)
          # Remove key to be tested from atts passed to `#create`
          construction_atts = H.first_values(atts).merge(key => nil).compact
          explicit = create factory, construction_atts 

          expect( explicit.attributes.values_at(*default_att_names ))
            .to eq(expected_values)
        end
      end
    end
  end
