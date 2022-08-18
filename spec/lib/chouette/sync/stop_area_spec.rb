# coding: utf-8
RSpec.describe Chouette::Sync::StopArea do

  describe Chouette::Sync::StopArea::Netex do

    let(:context) do
      Chouette.create do
        stop_area_provider objectid: "FR1-ARRET_AUTO"
      end
    end

    let(:target) { context.stop_area_referential }
    let(:stop_area_provider) { context.stop_area_provider }

    let(:xml) do
      %{
      <stopPlaces>
        <StopPlace dataSourceRef="FR1-ARRET_AUTO" version="811108" created="2016-10-23T22:00:00Z" changed="2019-04-02T09:43:08Z" id="FR::multimodalStopPlace:424920:FR1">
          <Name>Petits Ponts</Name>
          <Centroid>
            <Location>
              <gml:pos srsName="EPSG:2154">655945.0 6865765.5</gml:pos>
            </Location>
          </Centroid>
          <PostalAddress version="any" id="FR1:PostalAddress:424920:">
            <Town>Pantin</Town>
            <PostalRegion>93055</PostalRegion>
          </PostalAddress>
          <StopPlaceType>onstreetBus</StopPlaceType>
        </StopPlace>
        <StopPlace dataSourceRef="FR1-ARRET_AUTO" version="45624-811108" created="2014-12-29T14:31:51Z" changed="2019-04-02T09:43:08Z" id="FR::monomodalStopPlace:45624:FR1">
          <Name>Petits Ponts</Name>
          <Centroid>
            <Location>
              <gml:pos srsName="EPSG:2154">655945.0 6865765.5</gml:pos>
            </Location>
          </Centroid>
          <PostalAddress version="any" id="FR1:PostalAddress:45624:">
            <Town>Pantin</Town>
            <PostalRegion>93055</PostalRegion>
          </PostalAddress>
          <ParentSiteRef ref="FR::multimodalStopPlace:424920:FR1"/>
          <StopPlaceType>onstreetBus</StopPlaceType>
        </StopPlace>
      </stopPlaces>
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
      Chouette::Sync::StopArea::Netex.new source: source, target: target
    end

    let(:model_id_attribute) { Chouette::Sync::Base.default_model_id_attribute }

    let!(:existing_stop_area) do
      target.stop_areas.create! name: "Old Name", model_id_attribute => "FR::monomodalStopPlace:45624:FR1", stop_area_provider: stop_area_provider
    end

    let(:created_stop_area) do
      stop_area("FR::multimodalStopPlace:424920:FR1")
    end

    def stop_area(registration_number)
      target.stop_areas.find_by(model_id_attribute => registration_number)
    end

    it "should create the StopArea FR::multimodalStopPlace:424920:FR1" do
      sync.synchronize

      expected_attributes = {
        name: "Petits Ponts",
        area_type: "lda",
        object_version: 811108,
        city_name: "Pantin",
        postal_region: "93055",
        longitude: a_value_within(0.0000001).of(2.399185394712145),
        latitude: a_value_within(0.0000001).of(48.8903924223594),
        status: :confirmed
      }

      expect(created_stop_area).to have_attributes(expected_attributes)
    end

    it "should update the StopArea FR::monomodalStopPlace:45624:FR1" do
      sync.synchronize

      expected_attributes = {
        name: "Petits Ponts",
        area_type: "zdlp",
        object_version: 45624,
        city_name: "Pantin",
        postal_region: "93055",
        longitude: a_value_within(0.0000001).of(2.399185394712145),
        latitude: a_value_within(0.0000001).of(48.8903924223594),
        parent: stop_area("FR::multimodalStopPlace:424920:FR1"),
        status: :confirmed
      }
      expect(existing_stop_area.reload).to have_attributes(expected_attributes)
    end

    it "should destroy StopAreas no referenced in the source" do
      useless_stop_area =
        target.stop_areas.create! name: "Useless", model_id_attribute => "unknown", stop_area_provider: stop_area_provider
      sync.synchronize
      expect(useless_stop_area.reload).to be_deactivated
    end

  end

end
