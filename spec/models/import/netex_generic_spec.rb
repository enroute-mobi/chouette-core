RSpec.describe Import::NetexGeneric do

  let(:context) do
    Chouette.create do
      workbench
      code_space
    end
  end
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }

  def build_import(xml)
    Import::NetexGeneric.new(workbench: workbench, creator: "test", name: "test").tap do |import|
      allow(import).to receive(:netex_source) do
        Netex::Source.new.tap do |s|
          s.transformers << Netex::Transformer::Indexer.new(Netex::JourneyPattern, by: :route_ref)
          s.transformers << Netex::Transformer::Indexer.new(Netex::DayTypeAssignment, by: :day_type_ref)

          s.parse(StringIO.new(xml))
        end
      end
    end
  end

  let(:import) { build_import xml }

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

    context "when update_workgroup_providers option is enabled" do
      before do
        import.update options: { 'update_workgroup_providers' => true }
        workbench.stop_area_providers.create(objectid: 'FR1-ARRET_AUTO', name: 'stop_area_provider 1')
      end
      let(:stop_area_provider) { workbench.stop_area_providers.find_by(objectid: 'FR1-ARRET_AUTO') }

      let(:xml) do
        %{
          <stopPlaces>
            <StopPlace dataSourceRef="FR1-ARRET_AUTO" version="811108" created="2016-10-23T22:00:00Z" changed="2019-04-02T09:43:08Z" id="FR::multimodalStopPlace:424920:FR1">
              <Name>Petits Ponts</Name>
              <PostalAddress version="any" id="FR1:PostalAddress:424920:">
                <Town>Pantin</Town>
                <PostalRegion>93055</PostalRegion>
              </PostalAddress>
              <StopPlaceType>onstreetBus</StopPlaceType>
            </StopPlace>
          </stopPlaces>
        }
      end

      let(:expected_attributes) do
          an_object_having_attributes({
          name: "Petits Ponts",
          area_type: "lda",
          object_version: 811108,
          city_name: "Pantin",
          postal_region: "93055",
        })
      end

      context 'when stop_area_provider has id = "FR1-ARRET_AUTO"' do
        it 'should import stop area' do
          subject

          expect(stop_area_provider.stop_areas).to include(expected_attributes)
        end
      end

      context 'when stop_area_provider has no id = "FR1-ARRET_AUTO"' do

        before { stop_area_provider.update objectid: 'test' }

        let(:expected_message) do
          an_object_having_attributes(
            criticity: "error",
            message_key: "invalid_model_attribute",
            message_attributes: {
              "attribute_name"=>"provider",
              "attribute_value"=> "FR1-ARRET_AUTO"
            }
          )
        end

        let(:messages) { import.resources.first.messages }

        it 'should create an error message' do
          subject

          expect(messages).to include(expected_message)
        end
      end

      context 'when data_source_ref is empty' do
        let(:xml) do
          %{
            <stopPlaces>
            <StopPlace version="811108" created="2016-10-23T22:00:00Z" changed="2019-04-02T09:43:08Z" id="FR::multimodalStopPlace:424920:FR1">
              <Name>Petits Ponts</Name>
              <PostalAddress version="any" id="FR1:PostalAddress:424920:">
                <Town>Pantin</Town>
                <PostalRegion>93055</PostalRegion>
              </PostalAddress>
              <StopPlaceType>onstreetBus</StopPlaceType>
            </StopPlace>
          </stopPlaces>
          }
        end

        let!(:stop_area_provider) { workbench.default_stop_area_provider }
        let(:stop_areas) { stop_area_provider.reload.stop_areas }

        it 'should create a stop area with the default stop_area_provider' do
          subject

          expect(stop_areas).to include(expected_attributes)
        end
      end
    end

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
        before { allow(import).to receive(:stop_area_provider).and_return(stop_area.stop_area_provider) }
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
            before { allow(import).to receive(:stop_area_provider).and_return(stop_area.stop_area_provider) }
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
            before { allow(import).to receive(:stop_area_provider).and_return(stop_area.stop_area_provider) }
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

    context 'When XML contains stop place entrances' do
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

      let(:code_space) {workgroup.code_spaces.first}
      let(:stop_area) {::Chouette::StopArea.find_by_registration_number("stop-place-1")}

      context "when import has space code input" do
        let(:entrance) {::Entrance.by_code(code_space, "entrance-1").first}
        before do
          import.code_space = code_space
          import.part(:stop_area_referential).import!
        end

        it "should import stop_area" do
          expect(stop_area.reload).not_to be_nil
        end

        it "should import entrance" do
          expect(entrance.reload).not_to be_nil
        end

        it "should create association between stop_area and entrance" do
          expect(entrance&.stop_area).to eq(stop_area)
          expect(stop_area&.entrances).to eq([entrance])
        end
      end

      context "when import has no space code input" do
        let(:entrance) {::Entrance.by_code(import.code_space_default, "entrance-1").first}

        before { import.part(:stop_area_referential).import! }

        it "should import stop_area" do
          expect(stop_area.reload).not_to be_nil
        end

        it "should import entrance" do
          expect(entrance.reload).not_to be_nil
        end

        it "should create association between stop_area and entrance" do
          expect(entrance&.stop_area).to eq(stop_area)
          expect(stop_area&.entrances).to eq([entrance])
        end
      end
    end
  end

  describe 'Line Referential part' do

    context "when update_workgroup_providers option is enabled" do
      subject { import.part(:line_referential).import! }

      let(:code_space) { workgroup.code_spaces.default }
      before do
        import.update options: { 'update_workgroup_providers' => true }
        workbench.line_providers.create!(
          short_name: 'line_provider_1',
          name: 'line provider 1',
          codes_attributes: [{
            value: '2003-line-provider-existing',
            code_space: code_space
          }]
        )
      end
      let(:line_provider) { workbench.line_providers.by_code(code_space, '2003-line-provider-existing').first }

      let(:xml) do
        %{
          <frames>
          <ResourceFrame id="2003-enRoute:ResourceFrame:1" version="any">
            <organisations>
              <Operator id="2003-company-1" version="any">
                <Name>Demo Transit Authority</Name>
              </Operator>
            </organisations>
          </ResourceFrame>
          <ServiceFrame id="enRoute:ServiceFrame:1" version="any">
            <lines>
              <Line dataSourceRef="2003-line-provider-existing" id="2003-line-1" version="any">
                <Name>Airport - Bullfrog</Name>
                <TransportMode>bus</TransportMode>
                <OperatorRef ref="2003-company-1"/>
              </Line>
            </lines>
          </ServiceFrame>
          </frames>
        }
      end

      let(:expected_attributes) do
          an_object_having_attributes({
          name: "Airport - Bullfrog",
        })
      end

      context 'when line_provider has id' do
        it 'should import line' do
          subject

          expect(line_provider.reload.lines).to include(expected_attributes)
        end
      end

      context 'when line_provider has no id' do

        before { line_provider.codes.destroy_all }

        let(:expected_message) do
          an_object_having_attributes(
            criticity: "error",
            message_key: "invalid_model_attribute",
            message_attributes: {
              "attribute_name"=>"provider",
              "attribute_value"=> "2003-line-provider-existing"
            }
          )
        end

        let(:messages) { import.resources.last.messages }

        it 'should create an error message' do
          subject

          expect(messages).to include(expected_message)
        end
      end

      context 'when data_source_ref is empty' do
        let(:xml) do
          %{
            <frames>
              <ResourceFrame id="2003-enRoute:ResourceFrame:1" version="any">
                <organisations>
                  <Operator id="2003-company-1" version="any">
                    <Name>Demo Transit Authority</Name>
                  </Operator>
                </organisations>
              </ResourceFrame>
              <ServiceFrame id="enRoute:ServiceFrame:1" version="any">
                <lines>
                  <Line id="2003-line-2" version="any">
                    <Name>Bullfrog - Furnace Creek Resort</Name>
                    <TransportMode>bus</TransportMode>
                    <OperatorRef ref="2003-company-1"/>
                  </Line>
                </lines>
              </ServiceFrame>
            </frames>
          }
        end

        let!(:line_provider) { workbench.default_line_provider }
        let(:lines) { line_provider.reload.lines }
        let(:expected_attributes) do
            an_object_having_attributes({
              name: "Bullfrog - Furnace Creek Resort",
              line_provider_id: line_provider.id
          })
        end

        it 'should create a line with the default line_provider' do
          subject

          expect(lines).to include(expected_attributes)
        end
      end
    end

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
            let(:model) { import.workbench.line_referential.lines }

            it { is_expected.to match_array(["line-1", "line-2","line-3", "line-4", "line-5" ]) }
          end

          context "when model is LineNotice" do
            let(:model) { import.workbench.line_referential.line_notices }

            it { is_expected.to match_array(["notice-1", "notice-2" ]) }
          end

          context "when model is Company" do
            let(:model) { import.workbench.line_referential.companies }

            it { is_expected.to match_array(["company-1" ]) }
          end
        end

      describe "#associations" do

        context "when model is Line and association is company" do
          let(:company_registration_numbers) { import.workbench.line_referential.lines.map{ |line| line.company.registration_number }.uniq }

          it { expect(company_registration_numbers).to match_array(["company-1"]) }
        end

        context "when model is Company and association is Line" do
          let(:line_registration_numbers) { import.workbench.line_referential.companies.first.lines.map { |line| line.registration_number } }

          it { expect(line_registration_numbers).to match_array(["line-1", "line-2","line-3", "line-4", "line-5" ]) }
        end
      end
      end
    end

    describe '#accessibility' do
      subject { described_class.find_by(registration_number: 'test') }

      expected_attributes = {
        mobility_impaired_accessibility: "yes",
        wheelchair_accessibility: "yes",
        step_free_accessibility: "no",
        escalator_free_accessibility: "yes",
        lift_free_accessibility: "partial",
        audible_signals_availability: "partial",
        visual_signs_availability: "yes"
      }

      describe Chouette::Line do
        let(:xml) do
          %{
            <Line id="test">
              <Name>Line Sample</Name>
              <AccessibilityAssessment>
                <validityConditions>
                  <ValidityCondition>
                    <Description>Description Sample</Description>
                  </ValidityCondition>
                </validityConditions>
                <MobilityImpairedAccess>true</MobilityImpairedAccess>
                <limitations>
                  <AccessibilityLimitation>
                    <WheelchairAccess>true</WheelchairAccess>
                    <StepFreeAccess>false</StepFreeAccess>
                    <EscalatorFreeAccess>true</EscalatorFreeAccess>
                    <LiftFreeAccess>partial</LiftFreeAccess>
                    <AudibleSignalsAvailable>partial</AudibleSignalsAvailable>
                    <VisualSignsAvailable>true</VisualSignsAvailable>
                  </AccessibilityLimitation>
                </limitations>
              </AccessibilityAssessment>
            </Line>
          }
        end

        before { import.part(:line_referential).import! }

        it { is_expected.to an_object_having_attributes(expected_attributes) }
      end

      describe Chouette::StopArea do
        let(:xml) do
          %{
            <StopPlace id="test">
              <Name>Stop Place Sample</Name>
              <AccessibilityAssessment>
                <validityConditions>
                  <ValidityCondition>
                    <Description>Description Sample</Description>
                  </ValidityCondition>
                </validityConditions>
                <MobilityImpairedAccess>true</MobilityImpairedAccess>
                <limitations>
                  <AccessibilityLimitation>
                    <WheelchairAccess>true</WheelchairAccess>
                    <StepFreeAccess>false</StepFreeAccess>
                    <EscalatorFreeAccess>true</EscalatorFreeAccess>
                    <LiftFreeAccess>partial</LiftFreeAccess>
                    <AudibleSignalsAvailable>partial</AudibleSignalsAvailable>
                    <VisualSignsAvailable>true</VisualSignsAvailable>
                  </AccessibilityLimitation>
                </limitations>
              </AccessibilityAssessment>
            </StopPlace>
          }
        end

        before { import.part(:stop_area_referential).import! }

        it { is_expected.to an_object_having_attributes(expected_attributes) }
      end
    end
  end

  describe 'Shape Referential part' do

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

      context 'when no object exists' do
        describe '#models' do
          context 'when model is PointOfInterest::Base' do
            let(:model) { PointOfInterest::Base }
            let(:shape_provider) { import.workbench.default_shape_provider }
            let!(:category) { shape_provider.point_of_interest_categories.create(name: 'Category 2') }

            before { import.part(:shape_referential).import! }

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
                point_of_interest_category_id: category.id
              )
            end

            it { expect(model.all).to include(expected_point_of_interest_attributes) }
          end
        end
      end
    end
  end

  describe 'Scheduled Stop Points part' do
    let(:part) { import.part(:scheduled_stop_points) }

    subject do
      part.import!
      import.scheduled_stop_points
    end

    let(:context) do
      Chouette.create { stop_area registration_number: '123' }
    end
    let(:stop_area) { context.stop_area }

    let(:expected_attributes) do
      an_object_having_attributes(
        id: 'A',
        stop_area_id: stop_area.id
      )
    end

    before { allow(import).to receive(:stop_area_provider).and_return(stop_area.stop_area_provider) }

    context 'when XML contains QuayRef in PassengerStopAssignment' do
      let(:xml) do
        <<~XML
          <PassengerStopAssignment>
            <ScheduledStopPointRef ref="A"/>
            <QuayRef ref="123" />
          </PassengerStopAssignment>
        XML
      end

      it { is_expected.to include('A' => expected_attributes) }
    end

    context 'when XML contains StopPlaceRef in PassengerStopAssignment' do
      let(:xml) do
        <<~XML
          <PassengerStopAssignment>
            <ScheduledStopPointRef ref="A"/>
            <StopPlaceRef ref="123" />
          </PassengerStopAssignment>
        XML
      end

      it { is_expected.to include('A' => expected_attributes) }
    end

    context "when there is not stop place that has the id '123456'" do
      let(:xml) do
        <<~XML
          <PassengerStopAssignment>
            <ScheduledStopPointRef ref="A"/>
            <QuayRef ref="123456" />
          </PassengerStopAssignment>
        XML
      end

      let(:expected_message) do
        an_object_having_attributes(
          criticity: 'error',
          message_key: 'stop_area_not_found',
          message_attributes: {
            'code' => '123456'
          }
        )
      end

      it 'should create a message' do
        subject

        expect(part.import_resource.messages).to include(expected_message)
      end
    end
  end

  describe 'Routing Constraint Zones part' do
    let(:xml) do
      <<~XML
        <root>
          <RoutingConstraintZone id="test">
            <Name>Test</Name>
            <members>
              <ScheduledStopPointRef ref="A" />
              <ScheduledStopPointRef ref="B" />
            </members>
            <lines>
              <LineRef ref="1" />
            </lines>
          </RoutingConstraintZone>

          <ScheduledStopPoint id="A"/>

          <PassengerStopAssignment id="A">
            <ScheduledStopPointRef ref="A"/>
            <QuayRef ref="A" />
          </PassengerStopAssignment>

          <Quay id="A">
            <Name>Quay A</Name>
          </Quay>

          <ScheduledStopPoint id="B"/>

          <PassengerStopAssignment id="B">
            <ScheduledStopPointRef ref="B"/>
            <QuayRef ref="B" />
          </PassengerStopAssignment>

          <Quay id="B">
            <Name>Quay B</Name>
          </Quay>

          <Line id="1">
            <Name>Line Sample</Name>
          </Line>
        </root>
      XML
    end

    let(:line_provider) { import.line_provider }
    let(:line) { line_provider.lines.find_by_registration_number('1') }
    let(:line_routing_constraint_zones) { line_provider.line_routing_constraint_zones }
    let(:stop_area_ids) { import.stop_area_provider.stop_areas.where(registration_number: %w[A B]).pluck(:id) }

    before do
      import.part(:stop_area_referential).import!
      import.part(:line_referential).import!
      import.part(:scheduled_stop_points).import!
    end

    let(:expected_attributes) do
      an_object_having_attributes(
        name: 'Test',
        line_ids: [line.id],
        stop_area_ids: stop_area_ids
      )
    end

    subject { import.part(:routing_constraint_zones).import! }

    it 'should import routing constraint_zones' do
      expect { subject }.to change { line_routing_constraint_zones.count }.from(0).to(1)
      expect(line_routing_constraint_zones).to include(expected_attributes)
    end
  end

  describe 'Route and Journay Patterns part' do
    let(:xml) do
      <<-XML
        <members>
          <Route id="route-1">
            <Name>Route Sample</Name>
            <LineRef ref="line-1"/>
            <DirectionType>outbound</DirectionType>
          </Route>

          <ServiceJourneyPattern id="journeypattern-1">
            <Name>Journey Pattern 1</Name>
            <RouteRef ref="route-1"/>
            <pointsInSequence>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-11" order="1">
                <ScheduledStopPointRef ref="scheduled-stop-point-1"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-12" order="2">
                <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
              </StopPointInJourneyPattern>
            </pointsInSequence>
          </ServiceJourneyPattern>

          <ServiceJourneyPattern id="journeypattern-2">
            <Name>Journey Pattern 2</Name>
            <RouteRef ref="route-1"/>
            <pointsInSequence>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-21" order="1">
                <ScheduledStopPointRef ref="scheduled-stop-point-1"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-22" order="2">
                <ScheduledStopPointRef ref="scheduled-stop-point-2"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-23" order="3">
                <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
              </StopPointInJourneyPattern>
            </pointsInSequence>
          </ServiceJourneyPattern>

          <ServiceJourneyPattern id="journeypattern-3">
            <Name>Journey Pattern 3</Name>
            <RouteRef ref="route-1"/>
            <pointsInSequence>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-31" order="1">
                <ScheduledStopPointRef ref="scheduled-stop-point-2"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-32" order="2">
                <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
              </StopPointInJourneyPattern>
            </pointsInSequence>
          </ServiceJourneyPattern>

          <!-- Required resources -->

          <Line id="line-1">
            <Name>Line Sample</Name>
          </Line>

          <!-- Timetable -->
          <DayType id="daytype-1">
            <Name>Sample</Name>
            <properties>
              <PropertyOfDay>
                <DaysOfWeek>Monday Tuesday Wednesday Thursday Friday Saturday Sunday</DaysOfWeek>
              </PropertyOfDay>
            </properties>
          </DayType>

          <DayTypeAssignment id="assigment-1" order="0">
            <OperatingPeriodRef ref="period-1"/>
            <DayTypeRef ref="daytype-1"/>
          </DayTypeAssignment>

          <OperatingPeriod id="period-1">
            <FromDate>2030-01-01T00:00:00</FromDate>
            <ToDate>2030-01-10T00:00:00</ToDate>
          </OperatingPeriod>

          <!-- ScheduledStopPoint + PassengerStopAssignment + Quay -->
          <ScheduledStopPoint id="scheduled-stop-point-1"/>

          <PassengerStopAssignment id="passenger-stop-assignment-1" order="0">
            <ScheduledStopPointRef ref="scheduled-stop-point-1"/>
            <QuayRef ref="quay-1" />
          </PassengerStopAssignment>

          <Quay id="quay-1">
            <Name>Quay A</Name>
          </Quay>

          <!-- ScheduledStopPoint + PassengerStopAssignment + Quay -->
          <ScheduledStopPoint id="scheduled-stop-point-2"/>

          <PassengerStopAssignment id="passenger-stop-assignment-2" order="0">
            <ScheduledStopPointRef ref="scheduled-stop-point-2"/>
            <QuayRef ref="quay-2" />
          </PassengerStopAssignment>

          <Quay id="quay-2">
            <Name>Quay B</Name>
          </Quay>

          <!-- ScheduledStopPoint + PassengerStopAssignment + Quay -->
          <ScheduledStopPoint id="scheduled-stop-point-3"/>

          <PassengerStopAssignment id="passenger-stop-assignment-3" order="0">
            <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
            <QuayRef ref="quay-3" />
          </PassengerStopAssignment>

          <Quay id="quay-3">
            <Name>Quay C</Name>
          </Quay>
        </members>
      XML
    end

    before do
      import.part(:stop_area_referential).import!
      import.part(:line_referential).import!
      import.part(:scheduled_stop_points).import!

      import.within_referential do |referential|
        import.part(:route_journey_patterns).import!
      end
    end

    let(:new_referential) { Referential.where(name: 'test').last }
    let(:stop_areas) { new_referential&.stop_areas }
    let(:route) { new_referential.routes.first }

    describe 'StopArea' do
      subject { stop_areas.map(&:name) }

      it { is_expected.to match_array ['Quay A', 'Quay B', 'Quay C'] }
    end

    describe 'Route' do
      describe 'StopPoints in Route' do
        subject { route.stop_points.map{ |stop_point| stop_point.stop_area.name } }

        it { is_expected.to match_array ['Quay A', 'Quay B', 'Quay C'] }
      end

      describe 'JourneyPatterns in Route' do
        let(:journey_pattern) { route.journey_patterns.find_by(name: name) }
        subject { journey_pattern.stop_points.map{ |stop_point| stop_point.stop_area.name } }

        context 'with first journey pattern' do
          let(:name) { 'Journey Pattern 1' }

          it { is_expected.to match_array ['Quay A', 'Quay C'] }
        end

        context 'with second journey pattern' do
          let(:name) { 'Journey Pattern 2' }

          it { is_expected.to match_array ['Quay A', 'Quay B', 'Quay C'] }
        end

        context 'with last journey pattern' do
          let(:name) { 'Journey Pattern 3' }

          it { is_expected.to match_array ['Quay B', 'Quay C'] }
        end
      end
    end
  end

  describe 'TimeTables part' do
    let(:xml) do
      <<-XML
        <root>
          <Line id="line-1">
            <Name>Line Sample</Name>
          </Line> 
          
          <DayType id="daytype-1">
            <Name>Sample</Name>
            <properties>
              <PropertyOfDay>
                <DaysOfWeek>Tuesday Friday</DaysOfWeek>
              </PropertyOfDay>
            </properties>
          </DayType>
          
          <DayTypeAssignment id="assigment-1">
            <OperatingPeriodRef ref="period-1"/>
            <DayTypeRef ref="daytype-1"/>
          </DayTypeAssignment>
          
          <DayTypeAssignment id="assigment-2">
            <Date>2030-01-15</Date>
            <DayTypeRef ref="daytype-1"/>
            <isAvailable>true</isAvailable>
          </DayTypeAssignment>
          
          <OperatingPeriod id="period-1">
            <FromDate>2030-01-01T00:00:00</FromDate>
            <ToDate>2030-01-10T00:00:00</ToDate>
          </OperatingPeriod>
        </root>
      XML
    end

    before do
      import.part(:stop_area_referential).import!
      import.part(:line_referential).import!
      import.part(:scheduled_stop_points).import!

      import.within_referential do |referential|
        import.part(:route_journey_patterns).import!
        import.part(:time_tables).import!
      end
    end

    let(:new_referential) { Referential.where(name: 'test').last }
    let(:time_table) { new_referential.time_tables.find_by(comment: 'Sample')}

    describe '#effective_days' do
      let(:expected_dates) { ['2030-01-01', '2030-01-04', '2030-01-08', '2030-01-15'].map(&:to_date) }
      subject { time_table.effective_days }

      it { is_expected.to eq expected_dates}
    end

    describe '#included_days_in_dates_and_periods' do
      let(:expected_dates) do 
        [
          '2030-01-01', '2030-01-02', '2030-01-03', '2030-01-04',
          '2030-01-05', '2030-01-06', '2030-01-07', '2030-01-08',
          '2030-01-09', '2030-01-10', '2030-01-15'
        ].map(&:to_date)
      end

      subject { time_table.included_days_in_dates_and_periods }

      it { is_expected.to eq expected_dates}
    end
  end

  describe 'VehicleJourneys part' do
    let(:xml) do
      <<-XML
        <members>
          <Quay id="quay-1">
            <Name>Quay 1</Name>
          </Quay>
          <Quay id="quay-2">
            <Name>Quay 2</Name>
          </Quay>
          <Quay id="quay-3">
            <Name>Quay 3</Name>
          </Quay>
        
          <Line id="line">
            <Name>Line Sample</Name>
          </Line>
        
          <Route id="route">
            <Name>Route Sample</Name>
            <LineRef ref="line"/>
            <DirectionType>outbound</DirectionType>
          </Route>
        
          <ScheduledStopPoint id="scheduled-stop-point-1"/>
          <ScheduledStopPoint id="scheduled-stop-point-2"/>
          <ScheduledStopPoint id="scheduled-stop-point-3"/>
        
          <PassengerStopAssignment id="passenger-stop-assignment-1" order="1">
            <ScheduledStopPointRef ref="scheduled-stop-point-1"/>
            <QuayRef ref="quay-1"/>
          </PassengerStopAssignment>
          <PassengerStopAssignment id="passenger-stop-assignment-2" order="2">
            <ScheduledStopPointRef ref="scheduled-stop-point-2"/>
            <QuayRef ref="quay-2"/>
          </PassengerStopAssignment>
          <PassengerStopAssignment id="passenger-stop-assignment-3" order="3">
            <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
            <QuayRef ref="quay-3"/>
          </PassengerStopAssignment>
        
          <ServiceJourneyPattern id="journey-pattern-1">
            <Name>Journey Pattern Sample</Name>
            <RouteRef ref="route"/>
            <pointsInSequence>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-1" order="1">
                <ScheduledStopPointRef ref="scheduled-stop-point-1"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-2" order="2">
                <ScheduledStopPointRef ref="scheduled-stop-point-2"/>
              </StopPointInJourneyPattern>
              <StopPointInJourneyPattern id="stop-point-in-journey-pattern-3" order="3">
                <ScheduledStopPointRef ref="scheduled-stop-point-3"/>
              </StopPointInJourneyPattern>
            </pointsInSequence>
          </ServiceJourneyPattern>
        
          <ServiceJourney id="service-journey">
            <Name>Vehicle Journey Sample</Name>
            <dayTypes>
              <DayTypeRef ref="timetable"/>
            </dayTypes>
            <JourneyPatternRef ref="journey-pattern-1"/>
            <passingTimes>
              <TimetabledPassingTime>
                <DepartureTime>23:50:00</DepartureTime>
              </TimetabledPassingTime>
              <TimetabledPassingTime>
                <ArrivalTime>23:55:00</ArrivalTime>
                <DepartureTime>00:05:00</DepartureTime>
                <DepartureDayOffset>1</DepartureDayOffset>
              </TimetabledPassingTime>
              <TimetabledPassingTime>
                <ArrivalTime>00:15:00</ArrivalTime>
                <ArrivalDayOffset>1</ArrivalDayOffset>
              </TimetabledPassingTime>
            </passingTimes>
          </ServiceJourney>
        
          <DayType id="timetable">
            <Name>TimeTable Sample</Name>
            <properties>
              <PropertyOfDay>
                <DaysOfWeek>Monday Tuesday Wednesday Thursday Friday Saturday Sunday</DaysOfWeek>
              </PropertyOfDay>
            </properties>
          </DayType>
        
          <OperatingPeriod id="operation-period">
            <FromDate>2030-01-01T00:00:00</FromDate>
            <ToDate>2030-12-31T00:00:00</ToDate>
          </OperatingPeriod>
        
          <DayTypeAssignment id="day-type-assignment" order="1">
            <OperatingPeriodRef ref="operation-period" />
            <DayTypeRef ref="timetable"/>
          </DayTypeAssignment>
        </members>
      XML
    end

    before do
      import.part(:stop_area_referential).import!
      import.part(:line_referential).import!
      import.part(:scheduled_stop_points).import!

      import.within_referential do |referential|
        import.part(:route_journey_patterns).import!
        import.part(:time_tables).import!
        import.part(:vehicle_journeys).import!
      end
    end

    let(:new_referential) { Referential.where(name: 'test').last }
    let(:vehicle_journey) { new_referential.vehicle_journeys.find_by(published_journey_identifier: 'service-journey')}

    describe '#vehicle_journey' do
      subject { vehicle_journey }  
      let(:expected_attributes) do
        {
          published_journey_name: 'Vehicle Journey Sample',
          published_journey_identifier: 'service-journey'
        }
      end

      it { is_expected.to an_object_having_attributes(expected_attributes) }
    end

    describe '#journey_pattern' do
      subject { vehicle_journey.journey_pattern }  
      let(:expected_attributes) do
        { name: 'Journey Pattern Sample' }
      end

      it { is_expected.to an_object_having_attributes(expected_attributes) }
    end

    describe '#vehicle_journey_at_stops' do
      subject do 
        vehicle_journey.vehicle_journey_at_stops.map do |at_stop|
          {
            stop_area: at_stop.stop_point.stop_area.name,
            arrival_time: (at_stop.arrival_time.strftime('%H:%M') rescue nil),
            departure_time: (at_stop.departure_time.strftime('%H:%M') rescue nil)
          }
        end
      end

      let(:expected_attributes) do
        [
          {:stop_area=>"Quay 1", :arrival_time=>nil, :departure_time=>"23:50"}, 
          {:stop_area=>"Quay 2", :arrival_time=>"23:55", :departure_time=>"00:05"},
          {:stop_area=>"Quay 3", :arrival_time=>"00:15", :departure_time=>nil}
        ]
      end

      it { is_expected.to match_array expected_attributes }
    end
  end
end

RSpec.describe Import::NetexGeneric::TimeTables::Decorator do
  subject(:decorator) { described_class.new day_type, day_type_assignments, operating_periods }

  let(:day_type) { Netex::DayType.new }
  let(:day_type_assignments) { [] }
  let(:operating_periods) { [] }

  describe '#timetable_periods' do
    subject { decorator.timetable_periods }

    context 'when no Operation Period is defined' do
      it { is_expected.to be_empty }
    end

    # <OperatingPeriod>
    #   <FromDate>2030-01-01T00:00:00</FromDate>
    #   <ToDate>2030-01-10T00:00:00</ToDate>
    # </OperatingPeriod>
    context 'when an Operating Period is present from 2030-01-01 to 2030-01-10' do
      let(:operating_periods) do
        [
          Netex::OperatingPeriod.new(time_range: Time.parse('2030-01-01')..Time.parse('2030-01-10'))
        ]
      end

      let(:expected_period) do
        an_object_having_attributes(first: Date.parse('2030-01-01'), last: Date.parse('2030-01-10'))
      end

      it { is_expected.to contain_exactly(expected_period) }
    end

    context 'when an Operating Period and an UicOperatingPeriod are present' do
      let(:operating_periods) do
        [
          Netex::OperatingPeriod.new(time_range: Time.parse('2030-01-01')..Time.parse('2030-01-10')),
          Netex::UicOperatingPeriod.new
        ]
      end

      it { is_expected.to have_attributes(size: 1) }
    end
  end

  describe '#uic_days_bits' do
    subject { decorator.uic_days_bits }

    context 'when an UicOperatingPeriod is present from 2030-01-01 to 2030-01-10 with 1010110101' do
      let(:operating_periods) do
        [
          Netex::UicOperatingPeriod.new(
            time_range: Time.parse('2030-01-01')..Time.parse('2030-01-10'),
            valid_day_bits: '1010110101'
          )
        ]
      end

      let(:expected_days_bit) do
        an_object_having_attributes(
          from: Date.parse('2030-01-01'),
          to: Date.parse('2030-01-10'),
          bitset: Bitset.from_s('1010110101')
        )
      end

      it { is_expected.to contain_exactly(expected_days_bit) }
    end
  end

  describe '#memory_timetable' do
    subject { decorator.memory_timetable }

    context 'with an OperatingPeriod 2030-01-01..2030-01-10/MoTu, an UicOperatingPeriod from 2030-01-10/1000000001' do
      let(:day_type) do
        Netex::DayType.new(properties: [Netex::PropertyOfDay.new(days_of_week: 'monday tuesday')])
      end

      let(:operating_periods) do
        [
          Netex::OperatingPeriod.new(time_range: Time.parse('2030-01-01')..Time.parse('2030-01-10')),
          Netex::UicOperatingPeriod.new(
            time_range: Time.parse('2030-01-10')..Time.parse('2030-01-20'),
            valid_day_bits: '10000000001'
          )
        ]
      end

      it { is_expected.to include(Date.parse('2030-01-01')) }
      it { is_expected.not_to include(Date.parse('2030-01-02')) }
      it { is_expected.to include(Date.parse('2030-01-20')) }
    end
  end
end
