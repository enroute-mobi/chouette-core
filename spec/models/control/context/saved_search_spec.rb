# frozen_string_literal: true

RSpec.describe Control::Context::SavedSearch::Run do
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

  let!(:control_list) do
    Control::List.create! name: "Control List", workbench: workbench
  end

  let!(:control_context) do
    Control::Context::SavedSearch.create!(
      name: "Control Context Saved Search",
      control_list: control_list,
      saved_search_id: saved_search_id
    )
  end

  let!(:control_dummy) do
    Control::Dummy.create(
      name: "Control dummy",
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
      creator: user
    )
  end

  let(:control_context_runs) { control_list_run.control_context_runs }

  describe '.context' do
    before do
      control_list.reload
      control_list_run.build_with_original_control_list
      control_list_run.save
      control_list_run.reload
    end

    let(:control_context_run) { control_context_runs.find { |e| e.name == 'Control Context Saved Search' } }

    describe '#stop_areas' do
      let(:stop_areas) { control_context_run.stop_areas }

      it { expect(stop_areas).to match_array([first_stop_area, middle_stop_area]) }
    end
  end
end