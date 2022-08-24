RSpec.describe Chouette::Sync::PointOfInterest do

  describe Chouette::Sync::PointOfInterest::Netex do

    let(:context) do
      Chouette.create do
        shape_provider
        code_space short_name: 'external'
      end
    end

    let(:shape_provider) { context.shape_provider }
    let(:workgroup) { context.workgroup }
    let!(:alternate_code_space) { workgroup.code_spaces.create(short_name: 'osm')}
    let(:target) { shape_provider }
    let(:code_space) { context.code_space }
    let!(:category) { shape_provider.point_of_interest_categories.create(name: 'Category 2') }

    let(:xml) do
      <<~XML
      <pointOfInterests>
        <PointOfInterest dataSourceRef="data-source-ref-1" version="any" id="point_of_interest-1">
          <validityConditions>
            <AvailabilityCondition version="any" id="1">
              <dayTypes>
                <DayType version="any" id="1">
                  <properties>
                    <PropertyOfDay>
                      <DaysOfWeek>Monday Tuesday Wednesday Thursday Friday</DaysOfWeek>
                    </PropertyOfDay>
                  </properties>
                </DayType>
              </dayTypes>
              <timebands>
                <Timeband version="any" id="1">
                  <StartTime>08:30:00</StartTime>
                  <EndTime>17:30:00</EndTime>
                </Timeband>
              </timebands>
            </AvailabilityCondition>
        
            <AvailabilityCondition version="any" id="2">
              <dayTypes>
                <DayType version="any" id="2">
                  <Name>Working day</Name>
                  <properties>
                    <PropertyOfDay>
                      <DaysOfWeek>Saturday Sunday</DaysOfWeek>
                    </PropertyOfDay>
                  </properties>
                </DayType>
              </dayTypes>
              <timebands>
                <Timeband version="any" id="2">
                  <StartTime>10:30:00</StartTime>
                  <EndTime>12:30:00</EndTime>
                </Timeband>
              </timebands>
            </AvailabilityCondition>
          </validityConditions>
        
          <keyList>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>osm</Key>
              <Value>7817817891</Value>
            </KeyValue>
          </keyList>
        
          <Name>Frampton Football Stadium</Name>
        
          <Centroid>
            <Location>
              <Longitude>2.287592</Longitude>
              <Latitude>48.862725</Latitude>
            </Location>
          </Centroid>
        
          <Url>http://www.barpark.co.uk</Url>
          <PostalAddress version="any" id="2">
            <CountryName>France</CountryName>
          <AddressLine1>23 Foo St</AddressLine1>
          <Town>Frampton</Town>
          <PostCode>FGR 1JS</PostCode>
          </PostalAddress>
        
          <OperatingOrganisationView>
            <ContactDetails>
              <Email>ola@nordman.no</Email>
              <Phone>815 00 888</Phone>
            </ContactDetails>
          </OperatingOrganisationView>
        
          <classifications>
            <PointOfInterestClassificationView>
              <Name>Category 2</Name>
            </PointOfInterestClassificationView>
          </classifications>
      </PointOfInterest>
      </pointOfInterests>
      XML
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.transformers << Netex::Transformer::LocationFromCoordinates.new

        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::PointOfInterest::Netex.new source: source, target: target, code_space: code_space
    end

    let(:expected_point_of_interest_attributes) do
      an_object_having_attributes(
        name: 'Frampton Football Stadium',
        url: 'http://www.barpark.co.uk',
        address_line_1: '23 Foo St',
        zip_code: 'FGR 1JS',
        city_name: 'Frampton',
        country: 'France',
        phone: '815 00 888',
        email: 'ola@nordman.no',
        shape_provider_id: shape_provider.id,
        point_of_interest_category_id: category.id
      )
    end

    let(:expected_code_attributes) do
      an_object_having_attributes(
        value: 'point_of_interest-1',
        code_space_id: code_space.id
      )
    end

    let(:alternate_expected_code_attributes) do
      an_object_having_attributes(
        value: '7817817891',
        code_space_id: alternate_code_space.id
      )
    end

    context "when no point_of_interest exists" do

      before { sync.synchronize }

      it "should create codes" do
        expect(code_space.codes).to include(expected_code_attributes)
      end

      it "should create alternate codes" do
        expect(alternate_code_space.codes).to include(alternate_expected_code_attributes)
      end

      it "should import point_of_interests" do
        expect(target.point_of_interests).to include(expected_point_of_interest_attributes)
      end

      describe '#point_of_interest_hours' do
        subject { target.point_of_interests.map(&:point_of_interest_hours).flatten.count }

        it "should import point_of_interest_hours" do
          expect(subject).to eq(2)
        end
      end
    end

    context "when point_of_interest exists with codes" do

      before do
        shape_provider.point_of_interests.create(
          name: 'test_name',
          codes_attributes: [
            {
              value: 'data-source-ref-1',
              code_space_id: code_space.id
            }
          ]
        )

        sync.synchronize
      end

      it "should upddate point_of_interests" do
        expect(target.point_of_interests).to include(expected_point_of_interest_attributes)
      end

      describe '#point_of_interest_hours' do
        subject { target.point_of_interests.map(&:point_of_interest_hours).flatten.count }

        it "should import point_of_interest_hours" do
          expect(subject).to eq(2)
        end
      end
    end
  end
end