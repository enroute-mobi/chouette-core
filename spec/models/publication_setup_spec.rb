RSpec.describe PublicationSetup, type: :model, use_chouette_factory: true do
  it { should belong_to :workgroup }
  it { should have_many :destinations }
  it { should have_many :publications }
  it { should validate_presence_of :name }
  it { should validate_presence_of :workgroup }

  let!(:context) do
    Chouette.create do
      company :first_company
      line_provider :first_lp

      line :first, company: :first_company, line_provider: :first_lp
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
  let(:publication_setup) { PublicationSetup.new(workgroup: context.workgroup, export_options: { type: 'Export::Gtfs', line_ids: line_ids } ) }

  before(:each) { referential.switch }

  describe '.same_api_usage' do
    let!(:publication_setup1) { PublicationSetup.create(name: "PS1", workgroup: context.workgroup, export_options: { type: 'Export::NetexGeneric'} ) }
    let!(:publication_setup2) { PublicationSetup.create(name: "PS2", workgroup: context.workgroup, export_options: { type: 'Export::Ara'} ) }
    let!(:publication_setup3) { PublicationSetup.create(name: "PS3", workgroup: context.workgroup, export_options: { type: 'Export::Gtfs'} ) }

    context "when publication setup in argument doesn't exist" do
      let(:search_publication_setup) { PublicationSetup.new(name: "Search", workgroup: context.workgroup, export_options: { type: 'Export::Gtfs' } ) }
      it 'should return publication setups with same export_options type by default' do
        expect(PublicationSetup.same_api_usage(search_publication_setup)).to match_array([publication_setup3])
      end
    end

    context "when publication setup in argument exists" do
      let(:search_publication_setup) { PublicationSetup.create(name: "Search", workgroup: context.workgroup, export_options: { type: 'Export::Gtfs' } ) }
      it 'should return publication setups without the publication setup in argument if it exists' do
        expect(PublicationSetup.same_api_usage(search_publication_setup)).to match_array([publication_setup3])
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
