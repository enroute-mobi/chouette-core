# frozen_string_literal: true

RSpec.describe Control::Context::SavedSearch::Run do
  let(:context) do
    Chouette.create do
      workbench do
        referential
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:control_list) do
    Control::List.create! name: 'Control List', workbench: workbench
  end
  let(:control_context) do
    Control::Context::SavedSearch.create!(
      name: 'Control Context Saved Search',
      control_list: control_list,
      saved_search_id: saved_search_id
    )
  end
  let!(:control_dummy) do
    Control::Dummy.create(
      name: 'Control dummy',
      control_context: control_context,
      target_model: 'StopArea',
      position: 0
    )
  end
  let(:control_list_run) do
    Control::List::Run.new(
      name: 'Control List Run',
      referential: referential,
      workbench: workbench,
      original_control_list: control_list,
      creator: 'Test'
    ).tap do |mlr|
      mlr.build_with_original_control_list
      mlr.save!
    end
  end

  subject(:control_context_run) do
    control_list_run.control_context_runs.find { |e| e.name == 'Control Context Saved Search' }
  end

  describe '#scope' do
    subject { control_context_run.scope }

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
          initial_scope: control_context_run.context,
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
          initial_scope: control_context_run.context,
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
        is_expected.to eq(control_context_run.context)
      end
    end
  end
end
