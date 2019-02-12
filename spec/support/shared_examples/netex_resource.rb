RSpec.shared_examples_for 'it has default netex resource attributes' do |extra_params|
  it 'should have correct attributes' do
    Timecop.freeze '2000-01-01 12:00 UTC' do
      expect(node['version']).to eq 'any'
      expect(node['id']).to eq resource.objectid
      expect(node['created']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['changed']).to eq '2000-01-01T12:00:00.0Z'
      (extra_params || {}).each do |k, v|
        expect(node[k.to_s]).to eq v
      end
    end
  end
end

RSpec.shared_examples_for 'it has children matching attributes' do |matching|
  matching.each do |tag, attribute|
    it "should have a #{tag} child matching #{attribute} attribute" do
      expect(node.css(tag).size).to eq 1
      expect(node.css(tag).first.text.presence).to eq resource.send(attribute)
    end
  end
end

RSpec.shared_examples_for 'it has one child with value' do |tag, value|
  it "should have a #{tag} child with correct value" do
    expect(node.css(tag).size).to eq 1
    expect(node.css(tag).first.text.presence).to eq instance_exec(&value)
  end
end
