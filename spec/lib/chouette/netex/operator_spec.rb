RSpec.describe Chouette::Netex::Operator, type: :netex_resource do
  let(:resource){ create :company }
  let(:workgroup){ create :workgroup, line_referential: resource.line_referential }

  it_behaves_like 'it has default netex resource attributes'

  context 'with custom fields' do
    before(:each) do
      create :custom_field, field_type: :string, code: :energy, name: :energy, resource_type: "Company", workgroup: workgroup
      create :custom_field, field_type: :string, code: :energy2, name: :energy2, resource_type: "Company", workgroup: workgroup
    end

    it 'should have custom_fields' do
      resource.custom_field_values = { energy: 'foo', foo: 'bar', energy2: nil }
      expect(node.css('keyList').size) .to eq 1
      expect(node.css('keyList KeyValue').size) .to eq 1
      keyvalue = node.css('keyList KeyValue')[0]
      expect(keyvalue.css('Key')[0].text).to eq 'energy'
      expect(keyvalue.css('Value')[0].text).to eq 'foo'
    end
  end

  it_behaves_like 'it has children matching attributes', {
    'PublicCode' => :code,
    'CompanyCode' => :registration_number,
    'Name' => :name,
    'ShortName' => :short_name,
    'ContactDetails > Email' => :email,
    'ContactDetails > Phone' => :phone,
    'ContactDetails > Url' => :url
  }

  context 'without contact attributes' do
    before(:each) do
      resource.update email: nil, phone: nil, url: nil
    end
    it_behaves_like 'it has no child', 'ContactDetails'
  end
end
