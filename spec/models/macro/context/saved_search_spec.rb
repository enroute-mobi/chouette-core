# frozen_string_literal: true

RSpec.describe Macro::Context::SavedSearch::Run do
  let!(:organisation){create(:organisation)}
  let!(:user){create(:user, :organisation => organisation)}

  let(:context) do
    Chouette.create do
      stop_area :first, zip_code: 44300
      stop_area :middle, zip_code: 44300
      stop_area :last, zip_code: 00000

      referential do
        route stop_areas: %i[first middle last]
      end
    end
  end

  let(:referential) { context.referential }
  let(:workbench) { context.workbench }

  let(:first_stop_area) { context.stop_area(:first) }
  let(:middle_stop_area) { context.stop_area(:middle) }
  let(:last_stop_area) { context.stop_area(:last) }

  let(:saved_search_id) do 
    workbench.saved_searches.create(
      name: 'zip code 44300',
      search_attributes: { zip_code: '44300' },
      search_type: 'Search::StopArea'
    ).id
  end

  let!(:macro_list) do
    Macro::List.create! name: "Macro List", workbench: workbench
  end

  let!(:macro_context) do
    Macro::Context::SavedSearch.create!(
      name: "Macro Context Saved Search",
      macro_list: macro_list,
      saved_search_id: saved_search_id
    )
  end

  let!(:macro_dummy) do
    Macro::Dummy.create(
      name: "Macro dummy",
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
      creator: user
    )
  end

  let(:macro_context_runs) { macro_list_run.macro_context_runs }

  describe '.context' do
    before do
      referential.switch

      macro_list.reload
      macro_list_run.build_with_original_macro_list
      macro_list_run.save
      macro_list_run.reload
    end

    let(:macro_context_run) { macro_context_runs.find { |e| e.name == 'Macro Context Saved Search' } }

    describe '#stop_areas' do
      let(:stop_areas) { macro_context_run.scope.stop_areas }

      it { expect(stop_areas).to match_array([first_stop_area, middle_stop_area]) }
    end
  end
end