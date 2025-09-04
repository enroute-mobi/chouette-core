# frozen_string_literal: true

RSpec.describe PublicationSetup, type: :model, use_chouette_factory: true do
  it { is_expected.to belong_to(:workgroup).required }
  it { should have_many :destinations }
  it { should have_many :publications }
  it { should validate_presence_of :name }
  it { is_expected.to validate_numericality_of(:priority) }

  describe '.same_api_usage' do
    subject { described_class.same_api_usage(search_publication_setup) }

    let(:context) do
      Chouette.create do
        workgroup do
          publication_setup :publication_setup_gtfs, export_options: { type: 'Export::Gtfs' }
          publication_setup :publication_setup_netex, export_options: { type: 'Export::NetexGeneric' }
          publication_setup :publication_setup_ara, export_options: { type: 'Export::Ara' }
        end
      end
    end
    let(:search_publication_setup) do
      context.workgroup.publication_setups.new(name: 'Search', export_options: { type: 'Export::Gtfs' } )
    end

    context "when publication setup in argument doesn't exist" do
      it 'should return publication setups with same export_options type by default' do
        is_expected.to match_array([context.publication_setup(:publication_setup_gtfs)])
      end
    end

    context "when publication setup in argument exists" do
      before { search_publication_setup.save! }

      it 'should return publication setups without the publication setup in argument if it exists' do
        is_expected.to match_array([context.publication_setup(:publication_setup_gtfs)])
      end
    end
  end

  describe '#assign_attributes' do
    context 'instantiation of correct Export::Setup' do
      [
        ['Export::Gtfs', :ignore_extended_route_types, Export::Setup::Gtfs],
        ['Export::NetexGeneric', :skip_line_resources, Export::Setup::Netex],
        ['Export::Ara', :include_stop_visits, Export::Setup::Ara]
      ].each do |export_type, export_setup_attribute, export_setup_type|
        context "with '#{export_type}' as #export_type" do
          it 'when setting #export_type before #export_setup attribute' do
            publication_setup = described_class.new(
              export_type: export_type,
              export_setup: { export_setup_attribute => true }
            )
            expect(publication_setup.export_setup).to be_a(export_setup_type)
            expect(publication_setup.export_setup.send(export_setup_attribute)).to eq(true)
          end

          it 'when setting #export_setup attribute before #export_type' do
            publication_setup = described_class.new(
              export_setup: { export_setup_attribute => true },
              export_type: export_type
            )
            expect(publication_setup.export_setup).to be_a(export_setup_type)
            expect(publication_setup.export_setup.send(export_setup_attribute)).to eq(true)
          end
        end
      end
    end
  end

  describe '#export_type' do
    subject { publication_setup.export_type }

    [
      ['Export::Setup::Gtfs', 'Export::Gtfs'],
      ['Export::Setup::Netex', 'Export::NetexGeneric'],
      ['Export::Setup::Ara', 'Export::Ara']
    ].each do |export_setup_type, export_type|
      context "when #export_setup type is set to '#{export_setup_type}'" do
        let(:publication_setup) { described_class.new(export_setup: { type: export_setup_type }) }
        it { is_expected.to eq(export_type) }
      end
    end
  end

  describe '#publish' do
    let(:publication_setup) { create :publication_setup }
    let(:referential) { create :referential }

    before(:each) { referential.switch }

    it 'should create a Publication' do
      expect do
        publication_setup.publish(referential, creator: 'test')
      end.to change { publication_setup.publications.count }.by 1
    end
  end
end
