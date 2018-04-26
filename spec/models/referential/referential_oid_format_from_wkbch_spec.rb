RSpec.describe Referential do

  let( :legal_formats ){ described_class.objectid_format.values }


  describe 'default attributes' do

    context 'referential w/o an objectid_format' do
      let( :referential ){ described_class.new }
      let( :workbench ){ build_stubbed :workbench, objectid_format: random_element(legal_formats) }

      it "but a workbench will take the format of the workbench" do
        referential.workbench = workbench
        referential.define_default_attributes
        expect( referential.objectid_format ).to eq(workbench.objectid_format)
      end

      it 'and w/o a workbench will take the default objectid_format' do
        referential.define_default_attributes
        expect( referential.objectid_format ).to be_nil
      end
    end


    context 'referential with an objectid_format' do
      let( :distinct_formats ){ distinct_random_elements(legal_formats, count: 2) }

      let( :referential ){ build_stubbed :referential, objectid_format: distinct_formats.first}
      let( :workbench ){ build_stubbed :workbench, objectid_format: distinct_formats.second }

      it "and a workbench will not take the format of the workbench" do
        referential.workbench = workbench
        expect{ referential.define_default_attributes }.not_to change{ referential.objectid_format }
      end

      it 'and w/o a workbench will not take the default objectid_format' do
        expect{ referential.define_default_attributes }.not_to change{ referential.objectid_format }
      end
    end

  end



  describe 'self.new_from' do

    let( :source ){ build :referential }
    let( :functional_scope ){ double('functional scope') }

    it 'copies objectid_format from source' do
      expect( described_class )
        .to receive(:new)
        .with(name: I18n.t("activerecord.copy", name: source.name),
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
