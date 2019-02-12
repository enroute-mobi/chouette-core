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
      expect(node.css(tag).first.text.presence).to eq attr_to_val(attribute)
    end
  end
end

RSpec.shared_examples_for 'it has no child' do |name|
  it "should not have a #{name} child" do
    expect(node.css(name)).to be_empty, "No #{name} tag should be found in:\n #{node.to_xml}"
  end
end

RSpec.shared_examples_for 'it has one child with value' do |tag, attr|
  it "should have a #{tag} child with correct value" do
    expect(node.css(tag).size).to eq 1
    expect(node.css(tag).first.text.presence).to eq attr_to_val(attr)
  end
end

RSpec.shared_examples_for 'it has one child with ref' do |tag, attr|
  it "should have a #{tag} child with correct ref" do
    expect(node.css(tag).size).to eq 1
    expect(node.css(tag).first[:ref]).to eq attr_to_val(attr)
  end
end
