# coding: utf-8
RSpec.describe Chouette::Sync::Entrance do

  describe Chouette::Sync::Entrance::Netex do

    let(:context) do
      Chouette.create do
        stop_area registration_number: "stop-place-1"
        #stop_area_provider
      end
    end

    let(:target) { context.stop_area_referential }
    let(:stop_area_provider) { context.stop_area_provider }
    let(:stop_area) { context.stop_area }

    let(:xml) do
      %{
        <StopPlace id="stop-place-1" version="any">
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

    let(:expected_attributes) do 
      {
        name: "Centre ville",
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
    end

    context "when no entrance exists" do
      let(:created_stop_area_entrance) {target.entrances.where(model_id_attribute => "entrance-1").first}

      it "should create stop place entrance" do
        sync.synchronize

        expect(created_stop_area_entrance).to have_attributes(expected_attributes)
      end
    end

    context "when entrance exists" do
      let!(:existing_stop_area_entrance) do
        target.entrances.create!({
          name: "test",
          stop_area_provider: stop_area_provider,
          model_id_attribute => "entrance-1",
          stop_area: stop_area,
        })
      end

      it "should update stop place entrance" do
        sync.synchronize

        expect(existing_stop_area_entrance.reload).to have_attributes(expected_attributes)
      end
    end
  end
end
