RSpec.describe Chouette::Netex::Line do
  let(:line){ create :line, transport_submode: :demandAndResponseBus }

  let(:subject){ Chouette::Netex::Line.new(line) }
  let(:result) do
     Nokogiri::XML::Builder.new do |builder|
       subject.to_xml(builder)
     end
   end
   let(:node){ result.doc.css('Line').first }

  it 'should have correct attributes' do
    Timecop.freeze '2000-01-01 12:00 UTC' do
      expect(node['version']).to eq 'any'
      expect(node['id']).to eq line.objectid
      expect(node['created']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['changed']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['status']).to eq 'active'
    end
  end

  {
    'Name' => 'published_name',
    'Url' => 'url',
    'PublicCode' => 'number',
    'PrivateCode' => 'registration_number',
    'TransportMode' => 'transport_mode',
    'TransportSubmode' => 'transport_submode',
  }.each do |tag, attribute|
    it "should have a #{tag} child matching #{attribute} attribute" do
      expect(node.css(tag).size).to eq 1
      expect(node.css(tag).first.text.presence).to eq line.send(attribute)
    end
  end

  it 'should have OperatorRef' do
    expect(node.css('OperatorRef').size).to eq 1
    expect(node.css('OperatorRef').first.text.presence).to eq line.company.objectid
  end

  it 'should have RepresentedByGroupRef' do
    expect(node.css('RepresentedByGroupRef').size).to eq 1
    expect(node.css('RepresentedByGroupRef').first.text.presence).to eq line.network.objectid
  end
end
