# frozen_string_literal: true

RSpec.describe Search::Save, type: :model do
  subject(:saved_search) { described_class.new }

  class self::Search < ::Search::Base # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    attr_accessor :workgroup, :workbench
  end

  let(:context) do
    Chouette.create do
      workgroup do
        workbench
      end
    end
  end
  let(:workgroup) { context.workgroup }
  let(:workbench) { context.workbench }

  it { is_expected.to belong_to(:parent).required }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :search_type }

  describe '#model_name' do
    subject(:model_name) { saved_search.model_name }

    describe '#singular_route_key' do
      subject { model_name.singular_route_key }

      it { is_expected.to eq('search') }
    end

    describe '#route_key' do
      subject { model_name.route_key }

      it { is_expected.to eq('searches') }
    end
  end

  describe '#search' do
    subject { saved_search.search(search_context) }

    let(:search_context) { {} }

    before { saved_search.search_type = self.class::Search.to_s }

    context 'in workbench' do
      before { saved_search.parent = workbench }

      it 'instantiates search class with correct attributes' do
        expect(self.class::Search).to receive(:new).with(
          {
            saved_search: saved_search,
            workbench: workbench
          }
        )
        subject
      end

      it 'sets #last_used_at' do
        expect { subject }.to change { saved_search.last_used_at }.from(nil).to(be_present)
      end

      context 'with context' do
        let(:search_context) do
          {
            'attr2' => 'context_attr2',
            'attr3' => 'context_attr3'
          }
        end

        it 'instantiates search class with correct attributes erased in correct order' do
          saved_search.search_attributes = {
            'attr1' => 'search_attribute_attr1',
            'attr2' => 'bad_value'
          }
          expect(self.class::Search).to receive(:new).with(
            {
              saved_search: saved_search,
              workbench: workbench,
              'attr1' => 'search_attribute_attr1',
              'attr2' => 'context_attr2',
              'attr3' => 'context_attr3'
            }
          )
          subject
        end
      end
    end

    context 'in workgroup' do
      before { saved_search.parent = workgroup }

      it 'instantiates search class with correct attributes' do
        expect(self.class::Search).to receive(:new).with(
          {
            saved_search: saved_search,
            workgroup: workgroup
          }
        )
        subject
      end
    end
  end

  describe '.search_class_name' do
    subject { described_class.search_class_name(parent, resource_name) }

    let(:resource_name) { 'users' }

    context 'in workbench' do
      let(:parent) { workbench }

      it { is_expected.to eq('Search::User') }
    end

    context 'in workgroup' do
      let(:parent) { workgroup }

      it { is_expected.to eq('Search::WorkgroupUser') }
    end
  end

  describe '#resource_name' do
    subject { saved_search.resource_name }

    context 'in workbench' do
      before do
        saved_search.parent = workbench
        saved_search.search_type = 'Search::User'
      end

      it { is_expected.to eq('users') }
    end

    context 'in workgroup' do
      before do
        saved_search.parent = workgroup
        saved_search.search_type = 'Search::WorkgroupUser'
      end

      it { is_expected.to eq('users') }
    end
  end
end
