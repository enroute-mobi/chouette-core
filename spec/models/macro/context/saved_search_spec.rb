# frozen_string_literal: true

RSpec.describe Macro::Context::SavedSearch::Run do
  let(:context) do
    Chouette.create do
      workbench do
        referential
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:macro_list) do
    Macro::List.create! name: 'Macro List', workbench: workbench
  end
  let(:macro_context) do
    Macro::Context::SavedSearch.create!(
      name: 'Macro Context Saved Search',
      macro_list: macro_list,
      saved_search_id: saved_search_id
    )
  end
  let!(:macro_dummy) do
    Macro::Dummy.create(
      name: 'Macro dummy',
      macro_context: macro_context,
      target_model: 'StopArea',
      position: 0
    )
  end
  let(:macro_list_run) do
    Macro::List::Run.new(
      name: 'Macro List Run',
      referential: referential,
      workbench: workbench,
      original_macro_list: macro_list,
      creator: 'Test'
    ).tap do |mlr|
      mlr.build_with_original_macro_list
      mlr.save!
    end
  end

  subject(:macro_context_run) { macro_list_run.macro_context_runs.find { |e| e.name == 'Macro Context Saved Search' } }

  describe '#scope' do
    subject { macro_context_run.scope(initial_scope) }

    let(:initial_scope) { double(:initial_scope) }

    context 'with Line search' do
      let(:saved_search_id) do
        workbench.saved_searches.create(
          name: 'bus',
          search_attributes: { transport_mode: %i[bus] },
          search_type: 'Search::Line'
        ).id
      end

      it { is_expected.to be_a(Search::Line::Scope) }

      it do
        is_expected.to have_attributes(
          initial_scope: initial_scope,
          search: have_attributes(
            transport_mode: ['bus']
          )
        )
      end
    end

    context 'with StopArea search' do
      let(:saved_search_id) do
        workbench.saved_searches.create(
          name: 'zip code 44300',
          search_attributes: { zip_code: '44300' },
          search_type: 'Search::StopArea'
        ).id
      end

      it { is_expected.to be_a(Search::StopArea::Scope) }

      it do
        is_expected.to have_attributes(
          initial_scope: initial_scope,
          search: have_attributes(
            zip_code: '44300'
          )
        )
      end
    end

    context 'with search on any other model' do
      let(:saved_search_id) do
        workbench.saved_searches.create(
          name: 'Plop',
          search_attributes: { name: 'Plop' },
          search_type: 'Search::Import'
        ).id
      end

      it do
        is_expected.to eq(initial_scope)
      end
    end
  end
end
