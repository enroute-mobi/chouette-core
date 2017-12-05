RSpec.describe Referential do

  describe 'default attributes' do
    let( :referential ){ described_class.new }
    let( :workbench ){ Workbench.new }

    it "of a referential with a workbench contain the workbench's objectid_format" do
      ObjectidFormatterSupport.legal_formats.each do |legal_format|
        workbench.objectid_format = legal_format
        referential.workbench = workbench
        referential.define_default_attributes
        expect( referential.objectid_format ).to eq(legal_format)
      end
    end

    it 'of a referential w/o a workbench contain the default objectid_format' do
      referential.define_default_attributes
      expect( referential.objectid_format ).to eq(ObjectidFormatterSupport.default_format)
    end
  end
  

  describe 'self.new_from' do
    
    # Referential.new(
    #   name: 
    #   slug: "#{from.slug}_clone",
    #   prefix: from.prefix,
    #   time_zone: from.time_zone,
    #   bounds: from.bounds,
    #   line_referential: from.line_referential,
    #   stop_area_referential: from.stop_area_referential,
    #   created_from: from,
    #   metadatas: from.metadatas.map { |m| ReferentialMetadata.new_from(m, functional_scope) }
    # )
    #

    let( :source ){ build :referential }
    let( :functional_scope ){ double('functional scope') }

    it 'copies objectid_format from source' do
      expect( described_class )
        .to receive(:new)
              .with(name: I18n.t("activerecord.copy", name: source.name),
                    slug: "#{source.slug}_clone",
                    prefix: source.prefix,
                    time_zone: source.time_zone,
                    bounds: source.bounds,
                    line_referential: source.line_referential,
                    stop_area_referential: source.stop_area_referential,
                    created_from: source,
                    objectid_format: source.objectid_format,
                    metadatas: source.metadatas.map { |m| ReferentialMetadata.new_from(m, functional_scope) })
      
      described_class.new_from( source, functional_scope )
    end

  end
end
