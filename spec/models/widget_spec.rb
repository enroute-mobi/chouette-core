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
  let(:setup_data_cache_data) { 'whatever' }
  let(:setup_data_cache_version) { described_class::CACHE_VERSION }
  let(:setup_data_cache) { { 'data' => setup_data_cache_data, 'version' => setup_data_cache_version } }
  let(:widget) do
    dashboard.widgets.new(
      name: 'Test',
      widget_type: 'search',
      options: widget_options,
      setup_data_cache: setup_data_cache
    )
  end

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

  describe '#data_available?' do
    subject { widget_setup.data_available? }

    context 'without data in cache' do
      let(:setup_data_cache) { nil }

      it { is_expected.to be(false) }
    end

    context 'with data in cache' do
      it { is_expected.to be(true) }

      context 'with a different cache version' do
        let(:setup_data_cache_version) { "#{described_class::CACHE_VERSION}-00" }

        it { is_expected.to be(false) }
      end
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
      let(:setup_data_cache_data) { 42 }

      it 'returns the data in cache' do
        is_expected.to eq(42)
      end

      context 'on save' do
        before { widget.save! }

        it 'stores correct data in cache' do
          expect(widget.setup_data_cache).to eq({ 'data' => 2, 'version' => described_class::CACHE_VERSION })
        end

        it 'updates #setup_data_cache_updated_at' do
          expect(widget.setup_data_cache_updated_at).to be_present
        end

        context 'on change' do
          let(:other_saved_search) do
            workbench.saved_searches.create!(
              name: 'StopArea other',
              search_type: 'Search::StopArea',
              search_attributes: { 'text' => 'nope' }
            )
          end

          before { widget.setup = { 'saved_search_id' => other_saved_search.id } }

          it 'updates data in cache on save' do
            expect { widget.save! }.to change { widget.setup_data_cache }.to(
              { 'data' => 1, 'version' => described_class::CACHE_VERSION }
            )
          end
        end
      end
    end
  end

  describe '#chart' do
    subject { widget_setup.chart }

    context 'on stop areas' do
      let(:context) do
        Chouette.create do
          workbench :workbench do
            stop_area :stop_area1, zip_code: '44000', city_name: 'Nantes'
            stop_area :stop_area2, zip_code: '44000', city_name: 'Nantes'
            stop_area :stop_area3, zip_code: '44000', city_name: 'Nantes'
            stop_area :stop_area4, zip_code: '44000', city_name: 'Paris'
            stop_area :stop_area5, zip_code: '75000', city_name: 'Paris'
            stop_area :stop_area6, zip_code: '75000', city_name: 'Paris'
          end
        end
      end
      let(:widget_options) { { saved_search_id: saved_search.id } }

      context 'with xaxis' do
        let(:saved_search) do
          workbench.saved_searches.create!(
            name: 'StopArea',
            search_type: 'Search::StopArea',
            search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zip_code' }
          )
        end
        let(:setup_data_cache_data) { [['75000', 31], ['44000', 42]] }

        it 'returns the data in cache' do
          is_expected.to have_attributes(
            data: eq_with_keys_order({ '75000' => 31, '44000' => 42 })
          )
        end

        it 'stores correct data in cache on save' do
          expect { widget.save! }.to change { widget.setup_data_cache }.to(
            { 'data' => [['44000', 4], ['75000', 2]], 'version' => described_class::CACHE_VERSION }
          )
        end

        context 'when data is incompatible with chart' do
          let(:setup_data_cache_data) { [{ 'name' => 'Nantes', 'data' => [['75000', 6], ['44000', 2]] }] }

          it 'prevents crashes by returning nil' do
            is_expected.to be_nil
          end

          it 'captures error' do
            expect(Chouette::Safe).to receive(:capture)
            subject
          end
        end
      end

      context 'without xaxis' do
        let(:saved_search) do
          workbench.saved_searches.create!(
            name: 'StopArea',
            search_type: 'Search::StopArea',
            search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'updated_at', 'top_count' => 5 }
          )
        end
        let(:setup_data_cache_data) do
          [['2025-05-11', 1], ['2025-05-12', 0], ['2025-05-13', 5], ['2025-05-14', 2], ['2025-05-15', 0]]
        end

        before do
          Timecop.travel(DateTime.parse('2025-05-12T12:00:00')) do
            %i[stop_area1 stop_area2 stop_area3].each { |i| context.stop_area(i).touch }
          end
          Timecop.travel(DateTime.parse('2025-05-13T12:00:00')) do
            %i[stop_area3 stop_area4].each { |i| context.stop_area(i).touch }
          end
          Timecop.travel(DateTime.parse('2025-05-14T12:00:00')) do
            %i[stop_area5].each { |i| context.stop_area(i).touch }
          end
          Timecop.travel(DateTime.parse('2025-05-15T12:00:00'))
        end

        after { Timecop.return }

        it 'returns the data in cache' do
          is_expected.to have_attributes(
            data: { '2025-05-11' => 1, '2025-05-12' => 0, '2025-05-13' => 5, '2025-05-14' => 2, '2025-05-15' => 0 }
          )
        end

        it 'stores correct data in cache on save' do
          expect { widget.save! }.to change { widget.setup_data_cache }.to(
            {
              'data' => [['2025-05-11', 0], ['2025-05-12', 3], ['2025-05-13', 2], ['2025-05-14', 1], ['2025-05-15', 0]],
              'version' => described_class::CACHE_VERSION
            }
          )
        end
      end

      context 'with series' do
        let(:saved_search) do
          workbench.saved_searches.create!(
            name: 'StopArea',
            search_type: 'Search::StopArea',
            search_attributes: {
              'chart_type' => 'column', 'group_by_attribute' => 'zip_code', 'subgroup_by_attribute' => 'city_name'
            }
          )
        end
        let(:setup_data_cache_data) do
          [
            { 'name' => 'Nantes', 'data' => [['75000', 6], ['44000', 2]] },
            { 'name' => 'Paris', 'data' => [['75000', 0], ['44000', 1]] }
          ]
        end

        it 'returns the data in cache' do
          is_expected.to have_attributes(
            data: match(
              [
                { name: 'Nantes', data: eq_with_keys_order({ '75000' => 6, '44000' => 2 }) },
                { name: 'Paris', data: eq_with_keys_order({ '75000' => 0, '44000' => 1 }) }
              ]
            )
          )
        end

        it 'stores correct data in cache on save' do
          expect { widget.save! }.to change { widget.setup_data_cache }.to(
            {
              'data' => [
                { 'name' => 'Nantes', 'data' => [['44000', 3], ['75000', 0]] },
                { 'name' => 'Paris', 'data' => [['44000', 1], ['75000', 2]] }
              ],
              'version' => described_class::CACHE_VERSION
            }
          )
        end

        context 'when data is incompatible with chart' do
          let(:setup_data_cache_data) { [['75000', 31], ['44000', 42]] }

          it 'prevents crashes by returning nil' do
            is_expected.to be_nil
          end

          it 'captures error' do
            expect(Chouette::Safe).to receive(:capture)
            subject
          end
        end
      end
    end
  end
end

RSpec.describe Widget::StaticText do
  subject(:widget_setup) { widget.setup }

  let(:context) do
    Chouette.create do
      workbench :workbench
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:dashboard) { workbench.dashboards.create!(name: 'Test') }
  let(:content) { 'Content' }
  let(:widget_options) { { content: content } }
  let(:widget) { dashboard.widgets.new(name: 'Test', widget_type: 'static_text', options: widget_options) }

  it { is_expected.to validate_presence_of(:content) }

  describe '#data_available?' do
    subject { widget_setup.data_available? }

    it { is_expected.to be(true) }
  end
end
