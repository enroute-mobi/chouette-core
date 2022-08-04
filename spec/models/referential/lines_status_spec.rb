describe Referential::LinesStatus do

  let(:context) do
    Chouette.create { referential }
  end
  let(:referential) { context.referential }

  subject(:lines_status) { referential.lines_status }

  describe "#updated_at" do
    let(:line) { referential.lines.first }
    let(:metadata) { referential.metadatas.include_lines(line.id) }

    subject { lines_status.updated_at line }

    context "when Line metadata is created at 2030-01-01 12:00" do
      let(:time) { Time.zone.parse("2030-01-01 12:00") }
      before { metadata.update created_at: time }

      it { is_expected.to eq(time) }
    end

    context "when Line is not found" do
      let(:line) { Chouette::Line.new(id: "dummy") }
      it { is_expected.to be_nil }
    end
  end

  describe "as_json" do
    subject { lines_status.as_json }

    let(:line) { referential.lines.first }
    let(:metadata) { referential.metadatas.include_lines(line.id) }

    context "when the Line is named 'Line Sample'" do
      before { line.update name: "Line Sample"}
      it { is_expected.to include(a_hash_including(name: line.name)) }
    end

    context "when the Line has objectid 'test:Line:1:LOC'" do
      before { line.update objectid: 'test:Line:1:LOC'}
      it { is_expected.to include(a_hash_including(objectid: line.objectid)) }
    end

    context "when the Line is updated at 2030-01-01 12:00" do
      before { allow(lines_status).to receive(:updated_at).with(line).and_return(time) }
      let(:time) { Time.zone.parse("2030-01-01 12:00") }

      it { is_expected.to include(a_hash_including(updated_at: time)) }
    end

    context "when several lines are defined" do
      let(:context) do
        Chouette.create do
          line :first, name: "First"
          line :second, name: "Second"
          referential lines: [ :first, :second ]
        end
      end

      it { is_expected.to contain_exactly(a_hash_including(name: "First"), a_hash_including(name: "Second")) }
    end
  end

end
