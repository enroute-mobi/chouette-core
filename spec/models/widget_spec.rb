# frozen_string_literal: true

RSpec.describe Widget::Search do
  subject(:widget_setup) { widget.setup }

  let(:context) do
    Chouette.create do
      workbench :workbench
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:dashboard) { workbench.dashboards.create!(name: 'Test') }
  let(:widget_options) { {} }
  let(:widget) { dashboard.widgets.new(widget_type: 'search', options: widget_options) }

  describe '#candidate_searches' do
    subject { widget_setup.candidate_searches }

    let(:context) do
      Chouette.create do
        workbench :workbench
        workbench :other_workbench
      end
    end

    let!(:workbench_search1) do
      workbench.saved_searches.create!(
        name: 'StopArea 1 by name',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'by name' }
      )
    end
    let!(:workbench_search2) do
      workbench.saved_searches.create!(
        name: 'Line by name',
        search_type: 'Search::Line',
        search_attributes: { 'text' => 'by name' }
      )
    end
    let!(:other_workbench_search1) do
      context.workbench(:other_workbench).saved_searches.create!(
        name: 'StopArea 2 by name',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'by name' }
      )
    end

    it 'returns only searches of the widget workbench' do
      is_expected.to contain_exactly(workbench_search1, workbench_search2)
    end
  end

  describe '#scope' do
    subject { widget_setup.scope }

    context 'on stop areas' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area :stop_area1
              stop_area :stop_area2
            end
          end
          workgroup do
            workbench :other_workbench do
              stop_area
            end
          end
        end
      end
      let(:saved_search) do
        workbench.saved_searches.create!(
          name: 'StopArea',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'found' }
        )
      end
      let(:widget_options) { { saved_search_id: saved_search.id } }

      it 'returns only stop areas of the workbench' do
        is_expected.to match_array(%i[stop_area1 stop_area2].map { |i| context.stop_area(i) })
      end
    end
  end

  describe '#count' do
    subject { widget_setup.count }

    context 'on stop areas' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area name: 'found 1'
              stop_area name: 'found 2'
              stop_area name: 'nope'
            end
          end
          workgroup do
            workbench :other_workbench do
              stop_area name: 'found'
            end
          end
        end
      end
      let(:saved_search) do
        workbench.saved_searches.create!(
          name: 'StopArea',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'found' }
        )
      end
      let(:widget_options) { { saved_search_id: saved_search.id } }

      it 'counts only matching stop areas of the workbench' do
        is_expected.to eq(2)
      end
    end
  end

  describe '#chart' do
    subject { widget_setup.chart.data }

    context 'on stop areas' do
      let(:context) do
        Chouette.create do
          workbench :workbench do
            stop_area zip_code: '44000'
            stop_area zip_code: '44000'
            stop_area zip_code: '75000'
          end
        end
      end
      let(:saved_search) do
        workbench.saved_searches.create!(
          name: 'StopArea',
          search_type: 'Search::StopArea',
          search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zip_code' }
        )
      end
      let(:widget_options) { { saved_search_id: saved_search.id } }

      it 'returns chart data' do
        is_expected.to eq({ '44000' => 2, '75000' => 1 })
      end
    end
  end
end
