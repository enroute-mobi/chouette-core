# frozen_string_literal: true

RSpec.describe Cron::ComputeWidgetsSetupDataCacheJob do
  it { is_expected.to be_a_kind_of(Cron::MinutesJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    let(:context) do
      Chouette.create do
        workgroup :workgroup1 do
          workbench :workbench11 do
            stop_area name: 'found 1', zip_code: '75000'
            stop_area name: 'found 2', zip_code: '44000'
            stop_area name: 'nope', zip_code: '44000'
          end
          workbench :workbench12
        end
        workgroup :workgroup2 do
          workbench :workbench21
        end
      end
    end
    let(:dashboard111) { context.workbench(:workbench11).dashboards.create!(name: 'Wg1-Wb1-D1') }
    let(:dashboard112) { context.workbench(:workbench11).dashboards.create!(name: 'Wg1-Wb1-D2') }
    let(:dashboard121) { context.workbench(:workbench12).dashboards.create!(name: 'Wg1-Wb2-D1') }
    let(:dashboard211) { context.workbench(:workbench21).dashboards.create!(name: 'Wg2-Wb1-D1') }
    let(:saved_search_count11) do
      context.workbench(:workbench11).saved_searches.create!(
        name: 'Wg1-Wb1-count',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'found' }
      )
    end
    let!(:count_widget1111) do
      dashboard111.widgets.create!(
        name: 'Wg1-Wb1-D1-W1',
        widget_type: 'count',
        options: { saved_search_id: saved_search_count11.id }
      )
    end
    let(:saved_search_chart12) do
      context.workbench(:workbench11).saved_searches.create!(
        name: 'Wg1-Wb1-chart',
        search_type: 'Search::StopArea',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zip_code' }
      )
    end
    let!(:chart_widget1112) do
      dashboard111.widgets.create!(
        name: 'Wg1-Wb1-D1-W1',
        widget_type: 'chart',
        options: { saved_search_id: saved_search_chart12.id }
      )
    end
    let!(:static_text_widget1113) do
      dashboard111.widgets.create!(
        name: 'Wg1-Wb1-D1-W3',
        widget_type: 'static_text',
        options: { content: 'Some text' }
      )
    end
    let!(:count_widget1121) do
      dashboard112.widgets.create!(
        name: 'Wg1-Wb1-D2-W1',
        widget_type: 'count',
        options: { saved_search_id: saved_search_count11.id }
      )
    end
    let(:saved_search_count12) do
      context.workbench(:workbench12).saved_searches.create!(name: 'Wg1-Wb2-count', search_type: 'Search::StopArea')
    end
    let!(:count_widget1211) do
      dashboard121.widgets.create!(
        name: 'Wg1-Wb2-D1-W1',
        widget_type: 'count',
        options: { saved_search_id: saved_search_count12.id }
      )
    end
    let(:saved_search_count21) do
      context.workbench(:workbench21).saved_searches.create!(name: 'Wg2-Wb1-count', search_type: 'Search::StopArea')
    end
    let!(:count_widget2111) do
      dashboard211.widgets.create!(
        name: 'Wg2-Wb1-D1-W1',
        widget_type: 'count',
        options: { saved_search_id: saved_search_count21.id }
      )
    end

    before do
      context.workbench(:workbench11).default_stop_area_provider.stop_areas.create!(name: 'found 3', zip_code: '44000')
      Timecop.travel(1.day.from_now)
    end

    after { Timecop.return }

    it 'computes setup data cache of search count widget' do
      expect { subject }.to change { count_widget1111.reload.setup_data_cache }.to(include({ 'data' => 3 }))
    end

    it 'computes setup data cache of search chart widget' do
      expect { subject }.to change { chart_widget1112.reload.setup_data_cache }.to(
        include({ 'data' => [['44000', 3], ['75000', 1]] })
      )
    end

    it 'computes setup data cache of all search widgets' do
      expect { subject }.to change { count_widget1111.reload.setup_data_cache_updated_at }
                        .and change { chart_widget1112.reload.setup_data_cache_updated_at }
                        .and change { count_widget1121.reload.setup_data_cache_updated_at }
                        .and change { count_widget1211.reload.setup_data_cache_updated_at }
                        .and change { count_widget2111.reload.setup_data_cache_updated_at }
    end

    it 'does compute anything on non-search widgets' do
      expect { subject }.not_to(change { static_text_widget1113.reload.setup_data_cache_updated_at })
    end

    it 'computes setup data cache workgroup per workgroup' do
      expect(Chouette::Benchmark).to receive(:measure).with(
        :compute_widgets_setup_data_cache_for_workgroup,
        { workgroup_id: context.workgroup(:workgroup1).id }
      )
      expect(Chouette::Benchmark).to receive(:measure).with(
        :compute_widgets_setup_data_cache_for_workgroup,
        { workgroup_id: context.workgroup(:workgroup2).id }
      )
      subject
    end
  end
end
