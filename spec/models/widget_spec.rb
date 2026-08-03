# frozen_string_literal: true

RSpec.describe Widget::Setup do
  subject(:widget_setup) { widget_class.new }

  let(:widget_class) { Class.new(described_class) }
  let(:setup_data_cache_version) { '2026-06-03' }
  let(:setup_data_cache) { { 'data' => 'whatever', 'version' => setup_data_cache_version } }
  let(:widget) { Widget.new(name: 'Test', setup_data_cache: setup_data_cache) }

  before { widget_setup.parent = widget }

  describe '#setup_data_cache?' do
    subject { widget_setup.setup_data_cache? }

    context 'when CACHE_VERSION is not defined' do
      it { is_expected.to be(false) }
    end

    context 'when CACHE_VERSION is defined' do
      before { widget_class::CACHE_VERSION = '2026-06-03' }

      it { is_expected.to be(true) }
    end
  end

  describe '#data_available?' do
    subject { widget_setup.data_available? }

    context 'when #setup_data_cache? is false' do
      it { is_expected.to be(true) }
    end

    context 'when #setup_data_cache? is true' do
      before { widget_class::CACHE_VERSION = '2026-06-03' }

      context 'without data in cache' do
        let(:setup_data_cache) { nil }

        it { is_expected.to be(false) }
      end

      context 'with data in cache' do
        it { is_expected.to be(true) }

        context 'with a different cache version' do
          let(:setup_data_cache_version) { '2026-06-02' }

          it { is_expected.to be(false) }
        end
      end
    end
  end

  describe '#compute_setup_data_cache' do
    subject { widget_setup.compute_setup_data_cache }

    let(:valid) { true }

    before do
      widget_class::CACHE_VERSION = '2026-06-03'
      allow(widget_setup).to receive(:valid?).and_return(valid)
      allow(widget_setup).to receive(:compute_data_cache).and_return('whatever')
    end

    context 'when widget is invalid' do
      let(:valid) { false }

      it { is_expected.to be_nil }
    end

    context 'when widget is valid' do
      it { is_expected.to eq({ 'data' => 'whatever', 'version' => '2026-06-03' }) }
    end
  end
end

RSpec.describe Widget::Count do
  subject(:widget_setup) { widget.setup }

  let(:context) do
    Chouette.create do
      workbench :workbench
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:dashboard) { workbench.dashboards.create!(name: 'Test') }
  let(:saved_search) { nil }
  let(:setup_data_cache) { { 'data' => 42, 'version' => described_class::CACHE_VERSION } }
  let(:widget) do
    dashboard.widgets.new(
      name: 'Test',
      widget_type: 'count',
      options: { saved_search_id: saved_search&.id },
      setup_data_cache: setup_data_cache
    )
  end

  it { is_expected.to enumerize(:target_scope).in(%w[workbench last_merged_dataset last_aggregated_dataset]) }

  describe 'validations' do
    let(:candidate_search_ids) { [1, 42, 152] }
    let(:candidate_searches) do
      double('candidate_searches').tap do |candidate_searches|
        allow(candidate_searches).to receive(:pluck).with(:id).and_return(candidate_search_ids)
      end
    end

    before { allow(widget_setup).to receive(:candidate_searches).and_return(candidate_searches) }

    it { is_expected.to validate_inclusion_of(:saved_search_id).in_array(candidate_search_ids) }
  end

  describe '#candidate_searches' do
    subject { widget_setup.candidate_searches }

    let(:context) do
      Chouette.create do
        workbench :workbench
        workbench :other_workbench
      end
    end

    let!(:workbench_count_search1) do
      workbench.saved_searches.create!(
        name: 'StopArea 1 by name',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'by name' }
      )
    end
    let!(:workbench_count_search2) do
      workbench.saved_searches.create!(
        name: 'Line by name',
        search_type: 'Search::Line',
        search_attributes: { 'text' => 'by name' }
      )
    end
    let!(:workbench_count_referential_search1) do
      workbench.saved_searches.create!(
        name: 'ServiceCount 1 by transport mode',
        search_type: 'Search::ServiceCount',
        search_attributes: { 'transport_modes' => %w[bus] }
      )
    end
    let!(:workbench_chart_search) do
      workbench.saved_searches.create!(
        name: 'StopArea chart',
        search_type: 'Search::StopArea',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zip_code' }
      )
    end
    let!(:other_workbench_count_search) do
      context.workbench(:other_workbench).saved_searches.create!(
        name: 'StopArea 2 by name',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'by name' }
      )
    end

    context 'when #target_scope is "workbench"' do
      before { widget_setup.target_scope = 'workbench' }

      it 'returns only count searches on non-referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_count_search1, workbench_count_search2)
      end
    end

    context 'when #target_scope is "last_merged_dataset"' do
      before { widget_setup.target_scope = 'last_merged_dataset' }

      it 'returns only count searches on referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_count_referential_search1)
      end
    end

    context 'when #target_scope is "last_aggregated_dataset"' do
      before { widget_setup.target_scope = 'last_aggregated_dataset' }

      it 'returns only count searches on referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_count_referential_search1)
      end
    end
  end

  describe '#setup_data_cache?' do
    subject { widget_setup.setup_data_cache? }

    it { is_expected.to be(true) }
  end

  describe '#scope' do
    subject { widget_setup.scope }

    context 'on lines' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line1
              line :line2
              line :out_of_referential_line

              referential :referential, lines: %i[line1 line2]
            end
          end
          workgroup do
            workbench :other_workbench do
              line
            end
          end
        end
      end
      let(:saved_search) do
        workbench.saved_searches.create!(
          name: 'Line',
          search_type: 'Search::Line',
          search_attributes: { 'text' => 'found' }
        )
      end

      it 'returns only lines of the workbench' do
        is_expected.to match_array(%i[line1 line2 out_of_referential_line].map { |i| context.line(i) })
      end

      context 'when #target_scope is "last_merged_dataset"' do
        before { widget_setup.target_scope = 'last_merged_dataset' }

        context 'when there is no merged dataset' do
          it 'is empty' do
            is_expected.to be_empty
          end
        end

        context 'when there is a merged dataset' do
          let(:referential) { context.referential(:referential) }

          before do
            referential.update!(referential_suite: workbench.output)
            workbench.output.update!(current: referential)
          end

          it 'returns only lines of the referential' do
            is_expected.to match_array(%i[line1 line2].map { |i| context.line(i) })
          end
        end
      end

      context 'when #target_scope is "last_aggregated_dataset"' do
        before { widget_setup.target_scope = 'last_aggregated_dataset' }

        context 'when there is no aggregated dataset' do
          it 'is empty' do
            is_expected.to be_empty
          end
        end

        context 'when there is an aggregated dataset' do
          let(:referential) { context.referential(:referential) }

          before do
            referential.update!(referential_suite: workbench.workgroup.output)
            workbench.workgroup.output.update!(current: referential)
          end

          it 'returns only lines of the referential' do
            is_expected.to match_array(%i[line1 line2].map { |i| context.line(i) })
          end
        end
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
end

RSpec.describe Widget::Chart do
  subject(:widget_setup) { widget.setup }

  let(:context) do
    Chouette.create do
      workbench :workbench
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:dashboard) { workbench.dashboards.create!(name: 'Test') }
  let(:saved_search) { nil }
  let(:setup_data_cache_data) { 'whatever' }
  let(:setup_data_cache) { { 'data' => setup_data_cache_data, 'version' => described_class::CACHE_VERSION } }
  let(:widget) do
    dashboard.widgets.new(
      name: 'Test',
      widget_type: 'chart',
      options: { saved_search_id: saved_search&.id },
      setup_data_cache: setup_data_cache
    )
  end

  it { is_expected.to enumerize(:target_scope).in(%w[workbench last_merged_dataset last_aggregated_dataset]) }

  describe 'validations' do
    let(:candidate_search_ids) { [1, 42, 152] }
    let(:candidate_searches) do
      double('candidate_searches').tap do |candidate_searches|
        allow(candidate_searches).to receive(:pluck).with(:id).and_return(candidate_search_ids)
      end
    end

    before { allow(widget_setup).to receive(:candidate_searches).and_return(candidate_searches) }

    it { is_expected.to validate_inclusion_of(:saved_search_id).in_array(candidate_search_ids) }
  end

  describe '#candidate_searches' do
    subject { widget_setup.candidate_searches }

    let(:context) do
      Chouette.create do
        workbench :workbench
        workbench :other_workbench
      end
    end

    let!(:workbench_chart_search1) do
      workbench.saved_searches.create!(
        name: 'StopArea chart 1',
        search_type: 'Search::StopArea',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zipcode' }
      )
    end
    let!(:workbench_chart_search2) do
      workbench.saved_searches.create!(
        name: 'Import chart',
        search_type: 'Search::Import',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'status' }
      )
    end
    let!(:workbench_chart_referential_search1) do
      workbench.saved_searches.create!(
        name: 'ServiceCount chart 1',
        search_type: 'Search::ServiceCount',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'date' }
      )
    end
    let!(:workbench_count_search) do
      workbench.saved_searches.create!(
        name: 'StopArea by name',
        search_type: 'Search::StopArea',
        search_attributes: { 'text' => 'by name' }
      )
    end
    let!(:other_workbench_chart_search) do
      context.workbench(:other_workbench).saved_searches.create!(
        name: 'StopArea chart 2',
        search_type: 'Search::StopArea',
        search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zipcode' }
      )
    end

    context 'when #target_scope is "workbench"' do
      before { widget_setup.target_scope = 'workbench' }

      it 'returns only count searches on non-referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_chart_search1, workbench_chart_search2)
      end
    end

    context 'when #target_scope is "last_merged_dataset"' do
      before { widget_setup.target_scope = 'last_merged_dataset' }

      it 'returns only count searches on referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_chart_referential_search1)
      end
    end

    context 'when #target_scope is "last_aggregated_dataset"' do
      before { widget_setup.target_scope = 'last_aggregated_dataset' }

      it 'returns only count searches on referential models of the widget workbench' do
        is_expected.to contain_exactly(workbench_chart_referential_search1)
      end
    end
  end

  describe '#setup_data_cache?' do
    subject { widget_setup.setup_data_cache? }

    it { is_expected.to be(true) }
  end

  describe '#scope' do
    subject { widget_setup.scope }

    context 'on lines' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line1
              line :line2
              line :out_of_referential_line

              referential :referential, lines: %i[line1 line2]
            end
          end
          workgroup do
            workbench :other_workbench do
              line
            end
          end
        end
      end
      let(:saved_search) do
        workbench.saved_searches.create!(
          name: 'Line',
          search_type: 'Search::Line',
          search_attributes: { 'text' => 'found' }
        )
      end

      it 'returns only lines of the workbench' do
        is_expected.to match_array(%i[line1 line2 out_of_referential_line].map { |i| context.line(i) })
      end

      context 'when #target_scope is "last_merged_dataset"' do
        before { widget_setup.target_scope = 'last_merged_dataset' }

        context 'when there is no merged dataset' do
          it 'is empty' do
            is_expected.to be_empty
          end
        end

        context 'when there is a merged dataset' do
          let(:referential) { context.referential(:referential) }

          before do
            referential.update!(referential_suite: workbench.output)
            workbench.output.update!(current: referential)
          end

          it 'returns only lines of the referential' do
            is_expected.to match_array(%i[line1 line2].map { |i| context.line(i) })
          end
        end
      end

      context 'when #target_scope is "last_aggregated_dataset"' do
        before { widget_setup.target_scope = 'last_aggregated_dataset' }

        context 'when there is no aggregated dataset' do
          it 'is empty' do
            is_expected.to be_empty
          end
        end

        context 'when there is an aggregated dataset' do
          let(:referential) { context.referential(:referential) }

          before do
            referential.update!(referential_suite: workbench.workgroup.output)
            workbench.workgroup.output.update!(current: referential)
          end

          it 'returns only lines of the referential' do
            is_expected.to match_array(%i[line1 line2].map { |i| context.line(i) })
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
  let(:widget) { dashboard.widgets.new(name: 'Test', widget_type: 'static_text', options: { content: content }) }

  it { is_expected.to validate_presence_of(:content) }

  describe '#setup_data_cache?' do
    subject { widget_setup.setup_data_cache? }

    it { is_expected.to be(false) }
  end
end
