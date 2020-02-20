# coding: utf-8
RSpec.describe Chouette::Sync::StopArea do

  describe Chouette::Sync::StopArea::Netex do

    let(:context) do
      Chouette.create do
        stop_area_referential
      end
    end

    let(:target) { context.stop_area_referential }

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
        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::StopArea::Netex.new source: source, target: target
    end

    let!(:existing_stop_area) do
      target.stop_areas.create! name: "Old Name", registration_number: "FR::monomodalStopPlace:45624:FR1"
    end

    it "should create the StopArea FR::multimodalStopPlace:424920:FR1" do
      sync.synchronize

      expect(target.stop_areas.where(registration_number: "FR::multimodalStopPlace:424920:FR1")).to exist
    end

    it "should update the StopArea FR::monomodalStopPlace:45624:FR1" do
      sync.synchronize

      expected_attributes = {
        name: "Petits Ponts",
        object_version: 45624,
        city_name: "Pantin",
        postal_region: "93055",
      }
      expect(existing_stop_area.reload).to have_attributes(expected_attributes)
    end

    it "should destroy StopAreas no referenced in the source" do
      useless_stop_area =
        target.stop_areas.create! name: "Useless", registration_number: "unknown"
      sync.synchronize
      expect(target.stop_areas.where(id: useless_stop_area)).to_not exist
    end

  end

end
