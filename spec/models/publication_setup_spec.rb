
RSpec.describe PublicationSetup, type: :model, use_chouette_factory: true do
  it { should belong_to :workgroup }
  it { should have_many :destinations }
  it { should have_many :publications }
  it { should validate_presence_of :name }
  it { should validate_presence_of :workgroup }
  it { should validate_presence_of :export_type }

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

  let(:referential) { context.referential }
  let(:line_ids) { referential.lines.pluck(:id) }
  let(:publication_setup) { FactoryBot.create(:publication_setup, export_options: { line_ids: line_ids } ) }

  before(:each) { referential.switch }

  describe '#published_line_ids' do
    let(:workgroup) { referential.workgroup }
    let(:line_referential) { referential.line_referential }
    let(:line) { line_referential.lines.first }

    context 'when export_options.line_ids is defined' do
      it 'should return the selected line ids' do
        allow(publication_setup).to receive(:export_options) {{ line_ids: line_ids }}
        expect(publication_setup.published_line_ids(referential)).to eq(line_ids)
      end
    end

    context 'when export_options.company_ids is defined' do
      it 'should return the selected company ids' do
        company = FactoryBot.create(:company, line_referential: line_referential)
        line.update(company: company)
        publication_setup.export_options = { company_ids: [company.id] }

        expect(publication_setup.published_line_ids(referential)).to eq([line.id])
      end
    end

    context 'when export_options.line_provider_ids is defined' do
      it 'should return the selected line provider ids' do
        line_provider = FactoryBot.create(:line_provider, line_referential: line_referential)
        line.update(line_provider: line_provider)
        publication_setup.export_options = { line_provider_ids: [line_provider.id] }

        expect(publication_setup.published_line_ids(referential)).to eq([line.id])
      end
    end

    context 'when no line options is defined' do
      it 'should return all the lines associated to publication setup\'s workgroup' do
        publication_setup.export_options = {}
        expect(publication_setup.published_line_ids(referential)).to eq(publication_setup.workgroup.line_referential.lines.pluck(:id))
      end
    end
  end

  describe '#new_exports' do
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
