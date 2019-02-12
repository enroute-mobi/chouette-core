RSpec.shared_context 'with a netex resource' do
  let(:collection){ nil }
  let(:subject){ described_class.new(resource, collection) }

  let(:result) do
     Nokogiri::XML::Builder.new do |builder|
       subject.to_xml(builder)
     end
   end

   let(:node){ result.doc.children.first }

   before(:each) do
     described_class.reset_cache
   end
end

RSpec.configure do |conf|
  conf.include_context 'with a netex resource', type: :netex_resource
end

module NetexResource
  def attr_to_val(attr)
    if attr.is_a?(Proc)
      val = instance_exec &attr
    elsif attr.is_a?(Symbol)
      val = resource.send(attr)
    else
      val = attr
    end
  end
end

RSpec.configure do |conf|
  conf.include NetexResource, type: :netex_resource
end
