RSpec.describe Chouette::Netex::Operator do
  let(:company){ create :company }
  let(:workgroup){ create :workgroup, line_referential: company.line_referential }

  let(:subject){ Chouette::Netex::Operator.new(company) }
  let(:result) do
     Nokogiri::XML::Builder.new do |builder|
       subject.to_xml(builder)
     end
   end
   let(:node){ result.doc.css('Operator').first }

  it 'should have correct attributes' do
    Timecop.freeze '2000-01-01 12:00 UTC' do
      node = result.doc.css('Operator').first
      expect(node['version']).to eq 'any'
      expect(node['id']).to eq company.objectid
      expect(node['created']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['changed']).to eq '2000-01-01T12:00:00.0Z'
    end
  end

  context 'with custom fields' do
    before(:each) do
      create :custom_field, field_type: :string, code: :energy, name: :energy, resource_type: "Company", workgroup: workgroup
      create :custom_field, field_type: :string, code: :energy2, name: :energy2, resource_type: "Company", workgroup: workgroup
    end

    it 'should have custom_fields' do
      company.custom_field_values = { energy: 'foo', foo: 'bar', energy2: nil }
      expect(node.css('keyList').size) .to eq 1
      expect(node.css('keyList KeyValue').size) .to eq 1
      keyvalue = node.css('keyList KeyValue')[0]
      expect(keyvalue.css('Key')[0].text).to eq 'energy'
      expect(keyvalue.css('Value')[0].text).to eq 'foo'
    end

    {
      'PublicCode' => 'code',
      'CompanyCode' => 'registration_number',
      'Name' => 'name',
      'ShortName' => 'short_name',
      'ContactDetails > Email' => 'email',
      'ContactDetails > Phone' => 'phone',
      'ContactDetails > Url' => 'url'
    }.each do |tag, attribute|
      it "should have a #{tag} child matching #{attribute} attribute" do
        expect(node.css(tag).size).to eq 1
        expect(node.css(tag).first.text.presence).to eq company.send(attribute)
      end
    end
  end
end
