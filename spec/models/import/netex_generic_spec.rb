RSpec.describe Import::NetexGeneric do

  let(:context) { Chouette.create { workbench } }
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }

  def build_import(xml)
    Import::NetexGeneric.new(workbench: workbench, creator: "test", name: "test").tap do |import|
      allow(import).to receive(:netex_source) do
        Netex::Source.new.tap { |s| s.parse(StringIO.new(xml)) }
      end
    end
  end

  describe ".accepts_file?" do
    subject { Import::NetexGeneric.accepts_file?(filename) }

    context "when filename is file.xml" do
      let(:filename) { "file.xml" }
      it { is_expected.to be_truthy }
    end

    context "when file is Zip file with only .xml entries" do
      let(:filename) { fixtures_path("sample_neptune.zip") }
      it { is_expected.to be_truthy }
    end

    context "when file is GTFS file" do
      let(:filename) { fixtures_path("sample_gtfs.zip") }
      it { is_expected.to be_falsy }
    end
  end

  describe 'StopArea Referential Part' do

    subject { import.part(:stop_area_referential).import! }
    let(:import) { build_import xml }

    self::XML = '<StopPlace id="42"><Name>Tour Eiffel</Name></StopPlace>'
    context "when XML is #{self::XML}" do
      let(:xml) { self.class::XML }
      context "when no StopArea exists with the registration number '42'" do
        def stop_area
          workbench.stop_areas.find_by(registration_number: '42')
        end

        it { expect { subject }.to change { stop_area }.from(nil).to(an_object_having_attributes(registration_number: '42', name: 'Tour Eiffel')) }
      end

      context "when a StopArea exists with the registration number '42'" do
        let(:context) do
          Chouette.create { stop_area registration_number: '42' }
        end
        before { import.stop_area_provider = stop_area.stop_area_provider }
        let!(:stop_area) { context.stop_area }

        it { expect { subject ; stop_area.reload }.to change(stop_area, :name).from(a_string_not_matching('Tour Eiffel')).to('Tour Eiffel') }
      end

      describe 'resource' do
        subject(:resource) { import.resources.first }
        before { import.part(:stop_area_referential).import! }

        it { is_expected.to have_attributes(status: "OK", metrics: a_hash_including("error_count"=>"0","ok_count"=>"1")) }
      end
    end

    self::INVALID_XML = '<StopPlace id="test"><Name></Name></StopPlace>'
    context "when XML is #{self::INVALID_XML}" do
      let(:xml) { self.class::INVALID_XML }
      before { import.part(:stop_area_referential).import! }

      describe 'status' do
        subject { import.status }
        it { is_expected.to eq("failed") }
      end

      describe 'resource' do
        subject(:resource) { import.resources.first }
        it { is_expected.to have_attributes(status: "ERROR", metrics: a_hash_including("error_count"=>"1")) }
      end
    end

    describe 'attributes' do
      let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }
      before { import.part(:stop_area_referential).import!}

      def self::xml_with(content)
        %{
        <StopPlace id="test">
          <Name>Tour Eiffel</Name>
          #{content.strip}
        </StopPlace>
        }
      end

      describe 'name' do
        self::INVALID_XML = '<StopPlace id="test"><Name></Name></StopPlace>'

        context "when XML is #{self::INVALID_XML}" do
          let(:xml) { self.class::INVALID_XML }

          describe "resource messages" do
            let(:resource) { import.resources.first }
            subject { resource.messages }

            it do
              expected_message = an_object_having_attributes(
                criticity: "error",
                message_key: "invalid_model_attribute",
                message_attributes: {"attribute_name"=>"name", "attribute_value"=> nil}
              )
              is_expected.to include(expected_message)
            end
          end
        end
      end

      describe 'latitude' do
        subject { stop_area.latitude }
        self::XML = xml_with(
          %{
          <Centroid>
            <Location>
              <Latitude>48.8583701</Latitude>
              <Longitude>2.2922873</Longitude>
            </Location>
          </Centroid>
          }
        )
        context "when XML is #{self::XML}" do
          let(:xml) { self.class::XML }
          it { is_expected.to be_within(0.0000001).of(48.8583701) }
        end
      end

      describe 'longitude' do
        subject { stop_area.longitude }
        self::XML = xml_with(
          %{
          <Centroid>
            <Location>
              <Latitude>48.8583701</Latitude>
              <Longitude>2.2922873</Longitude>
            </Location>
          </Centroid>
          }
        )
        context "when XML is #{self::XML}" do
          let(:xml) { self.class::XML }
          it { is_expected.to be_within(0.0000001).of(2.2922873) }
        end
      end

      describe 'city_name' do
        subject { stop_area.city_name }
        self::XML = xml_with('<PostalAddress version="any"><Town>Paris</Town></PostalAddress>')
        context "when XML is #{self::XML}" do
          let(:xml) { self.class::XML }
          it { is_expected.to eq('Paris') }
        end
      end

      describe 'postal_region' do
        subject { stop_area.postal_region }
        self::XML = xml_with('<PostalAddress version="any"><PostalRegion>75107</PostalRegion></PostalAddress>')
        context "when XML is #{self::XML}" do
          let(:xml) { self.class::XML }
          it { is_expected.to eq('75107') }
        end
      end
    end

    context 'codes' do
      self::XML = %{
        <StopPlace id='test'>
          <Name>Test</Name>
          <keyList>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>code_space_shortname</Key>
              <Value>code_value</Value>
            </KeyValue>
          </keyList>
        </StopPlace>
      }

      subject(:codes) { stop_area.reload.codes }

      context "when XML is #{self::XML}" do
        let(:xml) { self.class::XML }

        context "when the required code space exists" do
          let!(:code_space) { workgroup.code_spaces.create!(short_name: 'code_space_shortname') }

          context "when no StopArea exists with this registration number" do
            let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }

            before { import.part(:stop_area_referential).import! }

            it { is_expected.to include(an_object_having_attributes(code_space_id: code_space.id, value: "code_value")) }
          end

          context "when a StopArea exists with this registration number" do
            let(:context) do
              Chouette.create { stop_area registration_number: 'test' }
            end
            before { import.stop_area_provider = stop_area.stop_area_provider }
            let!(:stop_area) { context.stop_area }

            before { import.part(:stop_area_referential).import! }

            it { is_expected.to include(an_object_having_attributes(code_space_id: code_space.id, value: "code_value")) }
          end
        end

        context "when the required code space doesn't exist" do
          let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }
          before { import.part(:stop_area_referential).import! }
          it { is_expected.to be_empty }

          describe "resource messages" do
            let(:resource) { import.resources.first }
            subject { resource.messages }

            it do
              expected_message = an_object_having_attributes(
                criticity: "error",
                message_key: "invalid_model_attribute",
                message_attributes: {"attribute_name"=>"codes", "attribute_value"=> "code_space_shortname"}
              )
              is_expected.to include(expected_message)
            end
          end
        end
      end

      self::XML_WITH_2_VALUES = %{
        <StopPlace id='test'>
          <Name>Test</Name>
          <keyList>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>code_space_shortname</Key>
              <Value>code_value1</Value>
            </KeyValue>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>code_space_shortname</Key>
              <Value>code_value2</Value>
            </KeyValue>
          </keyList>
        </StopPlace>
      }

      context "when XML is #{self::XML_WITH_2_VALUES}" do
        let(:xml) { self.class::XML_WITH_2_VALUES }

        let!(:code_space) { workgroup.code_spaces.create!(short_name: 'code_space_shortname') }
        let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }

        before { import.part(:stop_area_referential).import! }

        it do
          expected_codes = [
            an_object_having_attributes(code_space_id: code_space.id, value: "code_value1"),
            an_object_having_attributes(code_space_id: code_space.id, value: "code_value2")
          ]
          is_expected.to match_array(expected_codes)
        end
      end
    end

    context 'custom_fields' do
      self::XML = %{
        <StopPlace id='test'>
          <Name>Test</Name>
          <keyList>
            <KeyValue typeOfKey="chouette::custom-field">
              <Key>custom_field_code</Key>
              <Value>custom_field_value</Value>
            </KeyValue>
          </keyList>
        </StopPlace>
      }

      subject(:custom_field_values) { stop_area.reload.custom_field_values }

      context "when XML is #{self::XML}" do
        let(:xml) { self.class::XML }

        context "when the required code space exists" do
          let!(:custom_field) { workgroup.custom_fields.create!(code: 'custom_field_code', resource_type: "StopArea", field_type: "string" ) }

          context "when no StopArea exists with this registration number" do
            let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }

            before { import.part(:stop_area_referential).import! }

            it { is_expected.to include("custom_field_code" => "custom_field_value") }
          end

          context "when a StopArea exists with this registration number" do
            let(:context) do
              Chouette.create { stop_area registration_number: 'test' }
            end
            before { import.stop_area_provider = stop_area.stop_area_provider }
            let!(:stop_area) { context.stop_area }

            before { import.part(:stop_area_referential).import! }

            it { is_expected.to include("custom_field_code" => "custom_field_value") }
          end
        end

        context "when the required custom field doesn't exist" do
          let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }
          before { import.part(:stop_area_referential).import! }
          it { is_expected.to be_empty }

          describe "resource messages" do
            let(:resource) { import.resources.first }
            subject { resource.messages }

            it do
              expected_message = an_object_having_attributes(
                criticity: "error",
                message_key: "invalid_model_attribute",
                message_attributes: {"attribute_name"=>"custom_fields", "attribute_value"=> "custom_field_code"}
              )
              is_expected.to include(expected_message)
            end
          end
        end
      end
    end
  end

  describe 'Line Referential part' do
    let(:import) { build_import xml }

    context "when XML contains lines, operators and notices" do
      let(:xml) do
        %{
        <frames>
          <ResourceFrame id="enRoute:ResourceFrame:1" version="any">
            <organisations>
              <Operator id="company-1" version="any">
                <Name>Demo Transit Authority</Name>
              </Operator>
            </organisations>
            <notices>
              <Notice version="any" id="notice-1">
                <Name>First</Name>
                <Text>First text</Text>
                <TypeOfNoticeRef ref="LineNotice" />
              </Notice>
              <Notice version="any" id="notice-2">
                <Name>Second</Name>
                <Text>Second text</Text>
                <TypeOfNoticeRef ref="LineNotice" />
              </Notice>
          </notices>
          </ResourceFrame>
          <ServiceFrame id="enRoute:ServiceFrame:1" version="any">
            <lines>
              <Line id="line-1" version="any">
                <Name>Airport - Bullfrog</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="company-1"/>
              </Line>
              <Line id="line-2" version="any">
                <Name>Bullfrog - Furnace Creek Resort</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="company-1"/>
              </Line>
              <Line id="line-3" version="any">
                <Name>Stagecoach - Airport Shuttle</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="company-1"/>
              </Line>
              <Line id="line-4" version="any">
                <Name>City</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="company-1"/>
              </Line>
              <Line id="line-5" version="any">
                <Name>Airport - Amargosa Valley</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="company-1"/>
              </Line>
            </lines>
          </ServiceFrame>
        </frames>
        }
      end

      context "when no object exists" do
        before { import.part(:line_referential).import! }

        describe "#models" do
          subject { model.pluck(:registration_number) }

          context "when model is Line" do
            let(:model) { Chouette::Line }

            it { is_expected.to match_array(["line-1", "line-2","line-3", "line-4", "line-5" ]) }
          end

          context "when model is LineNotice" do
            let(:model) { Chouette::LineNotice }

            it { is_expected.to match_array(["notice-1", "notice-2" ]) }
          end

          context "when model is Company" do
            let(:model) { Chouette::Company }

            it { is_expected.to match_array(["company-1" ]) }
          end
        end

      describe "#associations" do

        context "when model is Line and association is company" do
          let(:company_registration_numbers) { Chouette::Line.all.map{ |line| line.company.registration_number }.uniq }

          it { expect(company_registration_numbers).to match_array(["company-1"]) }
        end

        context "when model is Company and association is Line" do
          let(:line_registration_numbers) { Chouette::Company.first.lines.map{ |line| line.registration_number } }

          it { expect(line_registration_numbers).to match_array(["line-1", "line-2","line-3", "line-4", "line-5" ]) }
        end
      end
      end
    end
  end

  describe 'Shape Referential part' do
    let(:import) { build_import xml }

    context "when XML contains PonitOfInterest" do
      let(:xml) do
        <<~XML
          <pointOfInterests>
            <PointOfInterest version="any" id="point_of_interest-1">
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
                <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
                <Key>osm</Key>
                <Value>999999999999</Value>
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

      context "when no object exists" do
        before { import.part(:shape_referential).import! }

        describe "#models" do

          context "when model is PointOfInterest::Base" do

            let(:model) { PointOfInterest::Base }

            let(:expected_point_of_interest_attributes) do
              an_object_having_attributes(
                name: 'Frampton Football Stadium',
                url: 'http://www.barpark.co.uk',
                address: '23 Foo St',
                zip_code: 'FGR 1JS',
                city_name: 'Frampton',
                country: 'France',
                phone: '815 00 888',
                email: 'ola@nordman.no',
              )
            end
            
            it { expect(model.all).to include(expected_point_of_interest_attributes) }
          end
        end
      end
    end
  end
end
