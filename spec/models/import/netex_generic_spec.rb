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
  end
end
