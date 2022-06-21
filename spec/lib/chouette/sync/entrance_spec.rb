# coding: utf-8
RSpec.describe Chouette::Sync::Entrance do

  describe Chouette::Sync::Entrance::Netex do

    let(:context) do
      Chouette.create do
        stop_area registration_number: "stop-place-1"
        code_space short_name: 'external'
      end
    end

    let(:target) { context.stop_area_provider }
    let(:stop_area_provider) { context.stop_area_provider }
    let(:stop_area) { context.stop_area }
    let(:code_space) { context.code_space }

    let(:xml) do
      <<~XML
        <StopPlace dataSourceRef="FR1-ARRET_AUTO" version="811108" created="2016-10-23T22:00:00Z" changed="2019-04-02T09:43:08Z" id="stop-place-1">
          <Name>North Ave </Name>
          <entrances>
            <StopPlaceEntranceRef ref="entrance-1" version="any"/>
          </entrances>
        </StopPlace>
        <StopPlaceEntrance id="entrance-1" version="any">
          <Name>Centre ville</Name>
          <Centroid version="any">
            <Location>
              <Longitude>2.292</Longitude>
              <Latitude>48.858</Latitude>
            </Location>
          </Centroid>
          <PostalAddress id="postal-address-1" version="any">
            <HouseNumber>123</HouseNumber>
            <AddressLine1>Address Line 1</AddressLine1>
            <AddressLine2>Address Line 2</AddressLine2>
            <Street>Route ST Félix</Street>
            <Town>Nantes</Town>
            <PostCode>44300</PostCode>
            <PostCodeExtension>44300</PostCodeExtension>
            <PostalRegion>44</PostalRegion>
            <CountryName>France</CountryName>
          </PostalAddress>
          <IsEntry>false</IsEntry>
          <IsExit>false</IsExit>
          <IsExternal>true</IsExternal>
          <Height>2</Height>
          <Width>3</Width>
          <EntranceType>opening</EntranceType>
        </StopPlaceEntrance>
      XML
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.transformers << Netex::Transformer::LocationFromCoordinates.new

        source.parse StringIO.new(xml)
      end
    end

    before do
      # In IBOO the stop_area_referential should use stif_reflex objectid_format
      if Chouette::Sync::Base.default_model_id_attribute == :objectid
        context.stop_area_referential.update objectid_format: "stif_reflex"
      end

      stop_area_provider.update objectid: "FR1-ARRET_AUTO"
    end

    subject(:sync) do
      Chouette::Sync::Entrance::Netex.new source: source, target: target, code_space: code_space
    end

    let(:model_id_attribute) { sync.model_id_attribute }

    let(:expected_attributes) do 
      {
        name: "Centre ville",
        entry_flag: false,
        exit_flag: false,
        entrance_type: "opening",
        address: "Address Line 1",
        zip_code: "44300",
        city_name: "Nantes",
        country: "France",
      }
    end

    context "when no entrance exists" do
      let(:created_stop_area_entrance) {target.entrances.by_code(code_space, "entrance-1").first}
      let(:created_code) {Code.find_by_value("entrance-1")}
      let(:expected_code_attributes) do
        {
          code_space_id: code_space&.id,
          resource_type: "Entrance",
          resource_id: created_stop_area_entrance&.id,
          value: "entrance-1",
        }
      end

      before do
        sync.synchronize
      end

      it "should create code" do
        expect(created_code).to have_attributes(expected_code_attributes)
      end

      it "should create stop place entrance" do
        expect(created_stop_area_entrance).to have_attributes(expected_attributes)
      end

      it "should create association between Entrances and Code" do
        expect( created_stop_area_entrance.codes).to match_array([created_code])
      end

    end

    context "when entrance exists" do
      let!(:existing_stop_area_entrance) do
        target.entrances.create!({
          name: "test",
          stop_area_provider: stop_area_provider,
          stop_area: stop_area,
          codes_attributes: [
            {
              code_space: code_space,
              value: "entrance-1"
            }
          ]
        })
      end

      it "should update stop place entrance" do
        sync.synchronize

        expect(existing_stop_area_entrance.reload).to have_attributes(expected_attributes)
      end
    end
  end
end
