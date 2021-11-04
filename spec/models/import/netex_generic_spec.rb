RSpec.describe Import::NetexGeneric do
	let(:workbench) do
    create :workbench do |workbench|
      workbench.line_referential.update objectid_format: "netex"
      workbench.stop_area_referential.update objectid_format: "netex"
    end
  end

  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:stop_area_provider) { workbench.stop_area_providers.first }

  let(:workbench_import){ create :workbench_import }

  def build_import(xml)
    i = Import::NetexGeneric.new workbench: workbench, creator: "test", name: "test", parent: workbench_import

    allow(i).to receive(:netex_source) do
      Netex::Source.new.tap { |s| s.parse(StringIO.new(xml)) }
    end

    i
  end

  def build_stop_area_xml(stop_area)
    %{
      <StopPlace dataSourceRef="#{stop_area_provider.objectid}" id="#{stop_area.registration_number}">
        <Name>#{stop_area.name}</Name>
        <Centroid>
          <Location>
            <gml:pos srsName="EPSG:4326">#{stop_area.latitude} #{stop_area.longitude}</gml:pos>
          </Location>
        </Centroid>
        <PostalAddress version="any">
          <Town>#{stop_area.city_name}</Town>
          <PostalRegion>#{stop_area.zip_code}</PostalRegion>
        </PostalAddress>
        <StopPlaceType>onstreetBus</StopPlaceType>
      </StopPlace>
    }
  end

  it 'should accept an xml file' do
    filename = 'test.xml'
    begin
      File.open(filename, 'w') do |f|
        stop_area = FactoryBot.build(:stop_area, stop_area_referential: stop_area_referential, stop_area_provider: stop_area_provider)
        f.write(build_stop_area_xml(stop_area))

        expect(Import::NetexGeneric.accepts_file?(filename)).to be_truthy
      end
    ensure
      File.delete(filename) if File.exists?(filename)
    end
  end

  it 'should accept a zip file' do
    expect(Import::NetexGeneric.accepts_file?(fixtures_path("sample_neptune.zip"),)).to be_truthy
  end

	describe '#import_stop_areas' do

    let(:stop_area) { FactoryBot.build(:stop_area, stop_area_referential: stop_area_referential, stop_area_provider: stop_area_provider) }

    let(:xml) { build_stop_area_xml(stop_area)}
    let(:import) { build_import(xml) }

    let(:imported_stop_areas) { workbench.stop_area_referential.stop_areas }

    it 'should create new stop_areas' do
      expect{ import.import_stop_areas }.to change{ imported_stop_areas.count }.by 1
      new_stop_area = Chouette::StopArea.find_by registration_number: stop_area.registration_number
      expect(new_stop_area.latitude).to eq(stop_area.latitude)
      expect(new_stop_area.longitude).to eq(stop_area.longitude)
      expect(new_stop_area.name).to eq(stop_area.name)
    end

    it 'should update existing stop_areas' do
      import.import_stop_areas

      new_stop_area = imported_stop_areas.last

      new_stop_area.update name: "Dummy"

      expect { import.import_stop_areas }.to change { new_stop_area.reload.name }.from("Dummy").to(stop_area.name)
    end
  end

  describe '#import_lines' do
  end

  describe '#import_companies' do
  end
end
