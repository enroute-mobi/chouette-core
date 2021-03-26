
RSpec.describe PublicationSetup, type: :model, use_chouette_factory: true do
  it { should belong_to :workgroup }
  it { should have_many :destinations }
  it { should have_many :publications }
  it { should validate_presence_of :name }
  it { should validate_presence_of :workgroup }
  it { should validate_presence_of :export_type }

  it 'should have at least one destination' do
    valid = FactoryBot.build(:publication_setup, destinations_count: 1)
    invalid = FactoryBot.build(:publication_setup, destinations_count: 0)

    expect(valid.valid?).to be_truthy
    expect(invalid.valid?).to be_falsey
  end

  describe '#new_exports' do
    let!(:context) do
      Chouette.create do
        line :first
        line :second
        
        referential lines: [:first, :second] do
          time_table :default

          route :in_scope1, line: :first do
            vehicle_journey :in_scope1, time_tables: [:default]
          end
          route :in_scope2, line: :second do
            vehicle_journey :in_scope2, time_tables: [:default]
          end
        end
      end
    end

    let(:referential) { context.referential}
    let(:line_ids) { referential.lines.pluck(:id) }
    let(:publication_setup) { FactoryBot.create(:publication_setup, export_options: { line_ids: line_ids } ) }

    before(:each) { referential.switch }

    context 'when published_per_line is set to true' do
      it 'should one export per line present in the export scope' do
        allow(publication_setup).to receive(:publish_per_lines) { true }
        exports = publication_setup.new_exports(referential)
        expect(exports.length).to eq(line_ids.length)
      end
    end

    context 'when published_per_line is set to false' do
      it 'should return only one export' do
        allow(publication_setup).to receive(:publish_per_lines) { false }
        exports = publication_setup.new_exports(referential)
        expect(exports.length).to eq(1)
      end
    end
  end

  describe '#publish' do
    let(:publication_setup) { create :publication_setup }
    let(:referential) { create :referential }
    let(:operation) { create :aggregate, new: referential }

    it 'should create a Publication' do
      expect{ publication_setup.publish(operation) }.to change{ publication_setup.publications.count }.by 1
    end
  end
end
