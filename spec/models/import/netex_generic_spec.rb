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

  describe '#import_stop_areas' do

    let(:import) { build_import xml }

    self::XML = '<StopPlace id="42"><Name>Tour Eiffel</Name></StopPlace>'
    context "when XML is #{self::XML}" do
      let(:xml) { self.class::XML }
      context "when no StopArea exists with the registration number '42'" do
        def stop_area
          workbench.stop_areas.find_by(registration_number: '42')
        end

        it { expect { import.import_stop_areas }.to change { stop_area }.from(nil).to(an_object_having_attributes(registration_number: '42', name: 'Tour Eiffel')) }
      end

      context "when a StopArea exists with the registration number '42'" do
        let(:context) do
          Chouette.create { stop_area registration_number: '42' }
        end
        before { import.stop_area_provider = stop_area.stop_area_provider }
        let!(:stop_area) { context.stop_area }

        it { expect { import.import_stop_areas ; stop_area.reload }.to change(stop_area, :name).from(a_string_not_matching('Tour Eiffel')).to('Tour Eiffel') }
      end

      describe 'resource' do
        subject(:resource) { import.resources.first }
        before { import.import_stop_areas }

        it { is_expected.to have_attributes(status: "OK", metrics: a_hash_including("error_count"=>"0","ok_count"=>"1")) }
      end
    end

    self::INVALID_XML = '<StopPlace id="test"><Name></Name></StopPlace>'
    context "when XML is #{self::INVALID_XML}" do
      let(:xml) { self.class::INVALID_XML }
      before { import.import_stop_areas }

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
      before { import.import_stop_areas }

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

            before { import.import_stop_areas }

            it { is_expected.to include(an_object_having_attributes(code_space_id: code_space.id, value: "code_value")) }
          end

          context "when a StopArea exists with this registration number" do
            let(:context) do
              Chouette.create { stop_area registration_number: 'test' }
            end
            before { import.stop_area_provider = stop_area.stop_area_provider }
            let!(:stop_area) { context.stop_area }

            before { import.import_stop_areas }

            it { is_expected.to include(an_object_having_attributes(code_space_id: code_space.id, value: "code_value")) }
          end
        end

        context "when the required code space doesn't exist" do
          let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }
          before { import.import_stop_areas }
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

        before { import.import_stop_areas }

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

            before { import.import_stop_areas }

            it { is_expected.to include("custom_field_code" => "custom_field_value") }
          end

          context "when a StopArea exists with this registration number" do
            let(:context) do
              Chouette.create { stop_area registration_number: 'test' }
            end
            before { import.stop_area_provider = stop_area.stop_area_provider }
            let!(:stop_area) { context.stop_area }

            before { import.import_stop_areas }

            it { is_expected.to include("custom_field_code" => "custom_field_value") }
          end
        end

        context "when the required custom field doesn't exist" do
          let(:stop_area) { workbench.stop_areas.find_by(registration_number: 'test') }
          before { import.import_stop_areas }
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

  describe '#import_lines' do
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
        before { import.import_lines }

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
end
