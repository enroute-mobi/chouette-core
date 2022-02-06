# coding: utf-8
RSpec.describe Chouette::Sync::Entrance do

  describe Chouette::Sync::Entrance::Netex do

    let(:context) do
      Chouette.create do
        stop_area registration_number: "stop-place-1"
        stop_area_provider
      end
    end

    let(:target) { context.stop_area_referential }
    let(:stop_area_provider) { context.stop_area_provider }

    let(:xml) do
      %{
        <StopPlace id="stop-place-1" version="any">
          <Name>North Ave </Name>
          <entrances>
            <StopPlaceEntranceRef ref="entrance-1" version="any"/>
          </entrances>
        </StopPlace>
        <StopPlaceEntrance id="entrance-1" version="any">
          <Name>test</Name>
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
      }
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
    end

    subject(:sync) do
      Chouette::Sync::Entrance::Netex.new source: source, target: target
    end

    let(:model_id_attribute) { Chouette::Sync::Base.default_model_id_attribute }

    let(:created_stop_area_entrance) {Entrance.find_by_registration_number("entrance-1")}

    it "should create stop place entrance" do
      sync.synchronize

      expected_attributes = {
        name: "test",
        entry_flag: false,
        exit_flag: false,
        entrance_type: "opening",
        address: "123 Route ST Félix",
        zip_code: "44300",
        city_name: "Nantes",
        country: "France",
        external_flag: true,
        width: 3.0,
        height: 2.0
      }
      expect(created_stop_area_entrance).to have_attributes(expected_attributes)
    end
  end
end
