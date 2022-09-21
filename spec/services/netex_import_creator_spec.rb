RSpec.describe NetexImportCreator do

  let(:netex_file) do
    # TL;DR Create a NeTEx IDFM Import file
    # With
    # * 2021-01-01 .. 2021-12-31 period
    # * an (empty) file for line 'A'

    directory_name = "test"

    calendars_xml = <<~XML
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<PublicationDelivery version="1.04:FR1-NETEX-2.0-d" xmlns="http://www.netex.org.uk/netex">
  <PublicationTimestamp>2020-09-25T06:44:29Z</PublicationTimestamp>
  <ParticipantRef>42</ParticipantRef>
  <dataObjects>
    <GeneralFrame version="any" id="enRoute:GeneralFrame:NETEX_CALENDRIER-2020-09-25T064429Z:LOC">
      <ValidBetween>
        <FromDate>2021-01-01T00:00:00</FromDate>
        <ToDate>2021-12-31T00:00:00</ToDate>
      </ValidBetween>
    </GeneralFrame>
  </dataObjects>
</PublicationDelivery>
    XML

    ligne_xml = <<~XML
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<PublicationDelivery version="1.04:FR1-NETEX-2.0-d" xmlns="http://www.netex.org.uk/netex">
  <PublicationTimestamp>2020-09-25T06:44:29Z</PublicationTimestamp>
  <ParticipantRef>42</ParticipantRef>
  <dataObjects>
    <CompositeFrame version="any" id="enRoute:CompositeFrame:NETEX_OFFRE_LIGNE-A:LOC">
      <Name>Test A</Name>
      <TypeOfFrameRef ref="FR1:TypeOfFrame:NETEX_OFFRE_LIGNE:">version="1.04:FR1-NETEX_OFFRE_LIGNE-2.1"</TypeOfFrameRef>
    </CompositeFrame>
  </dataObjects>
</PublicationDelivery>
    XML

    file = Tempfile.new(['netex-idfm', '.zip'])
    Zip::File.open(file, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream(File.join(directory_name, "calendriers.xml")) do |f|
        f.write calendars_xml
      end
      zipfile.get_output_stream(File.join(directory_name, "offre_A_testA.xml")) do |f|
        f.write ligne_xml
      end
    end

    file.flush
    file
  end

  let(:context) do
    Chouette.create do
      # workgroup import_types: %w{Import::Netex} do
        workbench do
          line objectid: "FR1:Line:A:"
          referential :existing
        end
      # end
    end
  end

  let(:workbench) { context.workbench }
  let(:workbench_import) { Import::Workbench.create! name: "Test", creator: "test", workbench: workbench, file: Rack::Test::UploadedFile.new(netex_file, "application/zip") }
  let(:creator) do
    attributes = {
      parent: workbench_import,
      name: "Test",
      workbench_id: workbench.id,
      file: netex_file,
      creator: "test"
    }
    NetexImportCreator.new workbench, attributes
  end

  def import
    creator.import
  end

  def error_messages
    # .. need to check import.parent.main_resource messages ?!
    import.main_resource.messages
  end

  describe "#netex_periods" do

    subject { creator.netex_periods }

    it "should use the values from NeTEx file" do
      is_expected.to eq([Date.parse('2021-01-01')..Date.parse('2021-12-31')])
    end

  end

  describe "#netex_line_objectids" do

    subject { creator.netex_line_objectids }

    it "should use the line_refs values from NeTEx file (with FR1:Line:XXX: format)" do
      is_expected.to eq(["FR1:Line:A:"])
    end

  end

  describe "#valid?" do

    subject { creator.valid? }

    context "when import is not valid" do

      before do
        allow(import).to receive(:valid?).and_return(false)
      end

      it { is_expected.to be_falsy }

      it "doesn't create any error message" do
        allow(creator).to receive(:netex_line_objectids).and_return([])
        expect { creator.valid? }.to_not change { error_messages }.from([])
      end

    end

    context "when netex_line_objectids is blank" do

      before do
        allow(import).to receive(:valid?).and_return(true)
        allow(creator).to receive(:netex_line_objectids).and_return([])
      end

      it { is_expected.to be_falsy }

      it "creates an error message" do
        creator.valid?
        expect(error_messages).to containing_exactly(an_object_having_attributes(message_key: "referential_creation_missing_lines_in_files"))

        # This smarter version doesn't work ?! :'(
        # https://github.com/rspec/rspec-expectations/pull/1132 ?
        #
        # expect { creator.valid? }.to change { error_messages }.from([]).to(a_collection_containing_exactly(an_object_having_attributes(message_key: "referential_creation_missing_lines_in_files")))
      end

    end

    context "when no associated line is found" do

      before do
        allow(import).to receive(:valid?).and_return(true)
        allow(creator).to receive(:lines).and_return([])
      end

      it { is_expected.to be_falsy }

      it "creates an error message" do
        creator.valid?
        expect(error_messages).to containing_exactly(an_object_having_attributes(message_key: "referential_creation_missing_lines"))
      end

    end

  end

  describe "#abort" do

    it "changes the import status to fail" do
      expect { creator.abort }.to change { import.status }.from("new").to("aborted")
    end

    it "leaves the creator not started" do
      expect { creator.abort }.to_not change { creator.started? }.from(a_falsy_value)
    end

  end

  describe "#referential_metadata" do

    subject { creator.referential_metadata }

    it "should use the netex_periods as periods" do
      is_expected.to have_attributes(periodes: creator.netex_periods)
    end

    it "should use the line identifiers associated to netex lines" do
      is_expected.to have_attributes(line_ids: creator.lines.map(&:id))
    end

  end

  describe "#referential" do

    subject { creator.referential }

    before { creator.init_referential }

    it "should use the import name as name" do
      is_expected.to have_attributes(name: creator.import.name)
    end

    it "should use the Workbench organisation" do
      is_expected.to have_attributes(organisation: creator.workbench.organisation)
    end

    it "should use the referential metadata created from netex data" do
      same_metadata = an_object_having_attributes(
        line_ids: creator.referential_metadata.line_ids,
        periodes: creator.referential_metadata.periodes
      )
      is_expected.to have_attributes(metadatas: containing_exactly(same_metadata))
    end

    it { is_expected.to have_attributes(ready: false) }

  end

  describe "#init_referential" do

    subject { creator.init_referential }

    context "when the referential is valid" do

      it "associates the referential to the import" do
        creator.init_referential
        expect(import.reload.referential).to eq(creator.referential)
      end

      it "associates the referential to the import main_resource" do
        creator.init_referential
        expect(import.reload.main_resource.referential).to eq(creator.referential)
      end

      it { is_expected.to be_truthy }

    end

    context "when the referential is not valid" do

      before { allow(creator.referential).to receive(:valid?).and_return(false) }

      context "if the created referential overlaps existing ones" do

        let(:overlapping_referential) { context.referential(:existing) }

        before do
          overlapped_referential_ids = [ overlapping_referential.id ]
          allow(creator.referential).to receive(:overlapped_referential_ids).and_return(overlapped_referential_ids)
        end

        it "creates an error message ('referential_creation_overlapping_existing_referential')" do
          creator.init_referential
          expect(error_messages).to containing_exactly(an_object_having_attributes(message_key: 'referential_creation_overlapping_existing_referential'))
        end

      end

      it "creates an error message ('referential_creation')" do
        creator.init_referential
        expect(error_messages).to containing_exactly(an_object_having_attributes(message_key: 'referential_creation'))
      end

      it { is_expected.to be_falsy }

    end

  end

  describe '#start' do

    context "when init_referential is successful (returns true)" do

      before { allow(creator).to receive(:init_referential).and_return(true) }

      it "starts the IEV import operation (aka invokes call_iev_callback)" do
        expect(creator.import).to receive(:call_iev_callback)
        creator.start
      end

      it "leaves the creator as started" do
        allow(creator.import).to receive(:call_iev_callback)
        expect { creator.start }.to change(creator, :started?).from(a_falsy_value).to(true)
      end

    end

    context "when init_referential fails (returns false)" do

      before { allow(creator).to receive(:init_referential).and_return(false) }

      it "aborts the import" do
        expect(creator).to receive(:abort)
        creator.start
      end

    end

  end

  describe "#to_yaml" do

    subject { creator.to_yaml }

    let(:expected_yaml) do
      <<~YAML
      --- !ruby/object:NetexImportCreator
      workbench_id: #{creator.workbench.id}
      import_id: #{creator.import.id}
      netex_periods:
      - !ruby/range
        begin: 2021-01-01
        end: 2021-12-31
        excl: false
      netex_line_objectids:
      - 'FR1:Line:A:'
      YAML
    end

    it "should contain workbench_id/import_id/netex_periods and netex_line_objectids" do
      is_expected.to eq(expected_yaml)
    end

  end

  context "after YAML reload" do

    subject { YAML.load creator.to_yaml }

    it "uses the same Workbench than the original creator" do
      is_expected.to have_attributes(workbench: creator.workbench)
    end

    it "uses the same Import than the original creator" do
      is_expected.to have_attributes(import: creator.import)
    end

    it "uses the same netex periods than the original creator" do
      is_expected.to have_attributes(netex_periods: creator.netex_periods)
    end

    it "uses the same netex line objectids than the original creator" do
      is_expected.to have_attributes(netex_line_objectids: creator.netex_line_objectids)
    end

  end

  describe "#create" do

    before { creator.inline_job = true }

    context "when the Creator is valid" do

      before { allow(creator).to receive(:valid?).and_return(true) }

      it "starts the import" do
        expect(creator).to receive(:start)
        creator.create
      end

    end

    context "when the Creator isn't valid" do

      before { allow(creator).to receive(:valid?).and_return(false) }

      it "aborts the import" do
        expect(creator).to receive(:abort)
        creator.create
      end

    end

  end

  describe '.enqueue_job' do
    subject { creator.enqueue_job }

    context 'when the Creator is in inline mode' do
      before { creator.inline_job = true }

      it 'invokes the method start' do
        expect(creator).to receive(:start)
        subject
      end
      it { is_expected.to be_nil }
    end

    context "when the Creator isn't in inline mode" do
      before { creator.inline_job = false }

      it { expect { subject }.to change(Delayed::Job, :count).by(1) }

      describe 'created job' do
        it { is_expected.to have_attributes(target_method: :start) }
        it { is_expected.to have_attributes(operation: creator) }
      end
    end
  end
end
