# frozen_string_literal: true

RSpec.describe Search::Import do
  subject(:search) { described_class.new }

  describe 'validation' do
    context 'when period is not valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => false)) }
      it { is_expected.to_not be_valid }
    end
    context 'when period is valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => true)) }
      it { is_expected.to be_valid }
    end
  end

  describe '#period' do
    subject { search.period }

    context 'when no start and end dates are defined' do
      before { search.start_date = search.end_date = nil }
      it { is_expected.to be_nil }
    end

    context 'when start date is defined' do
      before { search.start_date = Time.zone.today }
      it { is_expected.to have_same_attributes(:start_date, than: search) }
    end

    context 'when end date is defined' do
      before { search.end_date = Time.zone.today }
      it { is_expected.to have_same_attributes(:end_date, than: search) }
    end
  end

  describe '#candidate_statuses' do
    subject { search.candidate_statuses }

    Operation::UserStatus.all.each do |user_status| # rubocop:disable Rails/FindEach
      it "includes user status #{user_status}" do
        is_expected.to include(user_status)
      end
    end
  end

  describe '#candidate_workbenches' do
    subject { search.candidate_workbenches }

    context 'when no workgroup is associated' do
      before { search.workgroup = nil }
      it { is_expected.to be_empty }
    end

    context 'when a workgroup is defined' do
      before { search.workgroup = double(workbenches: double('Workgroup workbenches')) }
      it { is_expected.to eq(search.workgroup.workbenches) }
    end
  end

  describe '#workbenches' do
    subject { search.workbenches }

    it { is_expected.to be_empty }
  end

  describe '#query' do
    describe 'build' do
      let(:scope) { double }
      let(:query) { Query::Mock.new(scope) }

      before do
        allow(Query::Import).to receive(:new).and_return(query)
      end

      it 'uses Search workbenches' do
        allow(search).to receive(:workbenches).and_return(double)
        expect(query).to receive(:workbenches).with(search.workbenches).and_return(query)
        search.query(scope)
      end

      it 'uses Search name as text' do
        search.name = 'dummy'
        expect(query).to receive(:text).with(search.name).and_return(query)
        search.query(scope)
      end

      it 'uses Search statuses as user statuses' do
        allow(search).to receive(:statuses).and_return(double)
        expect(query).to receive(:user_statuses).with(search.statuses).and_return(query)
        search.query(scope)
      end

      it 'uses Search period' do
        allow(search).to receive(:period).and_return(double)
        expect(query).to receive(:in_period).with(search.period).and_return(query)
        search.query(scope)
      end
    end
  end

  describe '#chart' do
    subject(:chart) { search.chart(scope) }

    let(:context) do
      context = Chouette::Factory.create do
        workbench
      end
      workbench = context.workbench
      import_attributes = { type: 'Import::Gtfs', creator: 'test', file: open_fixture('google-sample-feed.zip') }
      workbench.imports.create!(import_attributes.merge(name: 'Import 1')).update_column(:status, 'successful')
      workbench.imports.create!(import_attributes.merge(name: 'Import 2')).update_column(:status, 'failed')
      workbench.imports.create!(import_attributes.merge(name: 'Import 3')).update_column(:status, 'successful')
      context
    end
    let(:search) do
      described_class.new(
        chart_type: 'line',
        group_by_attribute: group_by_attribute,
        top_count: 10
      )
    end
    let(:scope) { context.workbench.imports }

    describe '#data' do
      subject { chart.data }

      context 'with "status"' do
        let(:group_by_attribute) { 'status' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              I18n.t('imports.status.new') => 0,
              I18n.t('imports.status.pending') => 0,
              I18n.t('imports.status.successful') => 2,
              I18n.t('imports.status.warning') => 0,
              I18n.t('imports.status.failed') => 1,
              I18n.t('imports.status.running') => 0,
              I18n.t('imports.status.aborted') => 0,
              I18n.t('imports.status.canceled') => 0
            }
          )
        end
      end
    end
  end
end
