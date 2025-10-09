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

  describe 'validations' do
    describe 'name uniqueness' do
      before { saved_search.search_type = 'Whatever' }

      context 'in workgroup' do
        it 'can have a name already used in another workgroup with the same search_type' do
          context = Chouette.create do
            workgroup :workgroup1
            workgroup :workgroup2
          end
          Search::Save.create!(parent: context.workgroup(:workgroup2), name: 'Unique', search_type: 'Whatever')
          saved_search.parent = context.workgroup(:workgroup1)
          is_expected.to allow_value('Unique').for(:name)
        end

        it 'can have a name already used in a workbench inside workgroup with the same search_type' do
          context = Chouette.create do
            workgroup :workgroup do
              workbench :workbench
            end
          end
          Search::Save.create!(parent: context.workbench(:workbench), name: 'Unique', search_type: 'Whatever')
          saved_search.parent = context.workgroup(:workgroup)
          is_expected.to allow_value('Unique').for(:name)
        end

        context 'in the same workgroup' do
          let(:context) do
            Chouette.create do
              workgroup :workgroup
            end
          end

          it 'can have a name already used with another search_type' do
            Search::Save.create!(parent: context.workgroup(:workgroup), name: 'Unique', search_type: 'Other')
            saved_search.parent = context.workgroup(:workgroup)
            is_expected.to allow_value('Unique').for(:name)
          end

          it 'cannot have a name already used with the same search_type' do
            Search::Save.create!(parent: context.workgroup(:workgroup), name: 'Unique', search_type: 'Whatever')
            saved_search.parent = context.workgroup(:workgroup)
            is_expected.not_to allow_value('Unique').for(:name)
          end
        end
      end

      context 'in workbench' do
        it 'can have a name already used in another workbench with the same search_type' do
          context = Chouette.create do
            workbench :workbench1
            workbench :workbench2
          end
          Search::Save.create!(parent: context.workbench(:workbench2), name: 'Unique', search_type: 'Whatever')
          saved_search.parent = context.workbench(:workbench1)
          is_expected.to allow_value('Unique').for(:name)
        end

        it 'can have a name already used in a workgroup including its workbench with the same search_type' do
          context = Chouette.create do
            workgroup :workgroup do
              workbench :workbench
            end
          end
          Search::Save.create!(parent: context.workgroup(:workgroup), name: 'Unique', search_type: 'Whatever')
          saved_search.parent = context.workbench(:workbench)
          is_expected.to allow_value('Unique').for(:name)
        end

        context 'in the same workbench' do
          let(:context) do
            Chouette.create do
              workbench :workbench
            end
          end

          it 'can have a name already used with another search_type' do
            Search::Save.create!(parent: context.workbench(:workbench), name: 'Unique', search_type: 'Other')
            saved_search.parent = context.workbench(:workbench)
            is_expected.to allow_value('Unique').for(:name)
          end

          it 'cannot have a name already used with the same search_type' do
            Search::Save.create!(parent: context.workbench(:workbench), name: 'Unique', search_type: 'Whatever')
            saved_search.parent = context.workbench(:workbench)
            is_expected.not_to allow_value('Unique').for(:name)
          end
        end
      end
    end
  end

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
