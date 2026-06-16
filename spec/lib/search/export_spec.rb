# frozen_string_literal: true

RSpec.describe Search::Export, type: :model do
  subject(:search) { described_class.new }

  describe 'validation' do
    context 'when chart_type is present' do
      before { search.chart_type = 'line' }

      it { is_expected.to allow_value('started_at').for(:group_by_attribute) }
      it { is_expected.to allow_value('started_at_hour_of_day').for(:group_by_attribute) }
      it { is_expected.to allow_value('started_at_day_of_week').for(:group_by_attribute) }
    end

    context 'when period is not valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => false)) }
      it { is_expected.to_not be_valid }
    end

    context 'when period is valid' do
      before { allow(search).to receive(:period).and_return(double('valid?' => true)) }
      it { is_expected.to be_valid }
    end
  end

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Export::Base) }
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
        allow(Query::Export).to receive(:new).and_return(query)
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

    let(:context) do # rubocop:disable Metrics/BlockLength
      context = Chouette::Factory.create do
        workgroup export_types: ['Export::Gtfs'] do
          workbench do
            referential
          end
        end
      end
      workbench = context.workbench
      export_attributes = {
        type: 'Export::Gtfs',
        creator: 'test',
        workgroup: context.workgroup,
        referential: context.referential,
        setup: { scope_setup: { type: 'Export::Setup::Scope::Referential' } }
      }
      workbench.exports.create!(export_attributes.merge(name: 'Export 1')).update_columns(
        status: 'successful',
        started_at: DateTime.parse('2007-01-01T01:01:01'),
        ended_at: DateTime.parse('2007-01-01T02:01:01')
      )
      workbench.exports.create!(export_attributes.merge(name: 'Export 2')).update_columns(
        status: 'failed',
        started_at: DateTime.parse('2007-01-02T03:01:01'),
        ended_at: DateTime.parse('2007-01-02T04:01:01')
      )
      workbench.exports.create!(export_attributes.merge(name: 'Export 3')).update_columns(
        status: 'successful',
        started_at: DateTime.parse('2008-01-01T01:01:01'),
        ended_at: DateTime.parse('2008-01-01T01:31:01')
      )
      context
    end
    let(:aggregate_operation) { 'count' }
    let(:aggregate_attribute) { nil }
    let(:search) do
      described_class.new(
        chart_type: 'line',
        group_by_attribute: group_by_attribute,
        aggregate_operation: aggregate_operation,
        aggregate_attribute: aggregate_attribute,
        top_count: 10
      )
    end
    let(:scope) { context.workbench.exports }

    describe '#data' do
      subject { chart.data }

      context 'with group_by_attribute "started_at"' do
        let(:group_by_attribute) { 'started_at' }

        it 'returns correct data' do
          today = Time.zone.today
          is_expected.to eq((0...10).map { |i| [today - i, 0] }.to_h)
        end

        context 'with filter on period' do
          before do
            search.start_date = Time.zone.parse('2007-01-01')
            search.end_date = Time.zone.parse('2007-01-02')
          end

          it 'returns correct data' do
            is_expected.to eq(
              Date.parse('2007-01-01') => 1,
              Date.parse('2007-01-02') => 1
            )
          end
        end
      end

      context 'with group_by_attribute "status"' do
        let(:group_by_attribute) { 'status' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              I18n.t('exports.status.new') => 0,
              I18n.t('exports.status.pending') => 0,
              I18n.t('exports.status.successful') => 2,
              I18n.t('exports.status.warning') => 0,
              I18n.t('exports.status.failed') => 1,
              I18n.t('exports.status.running') => 0,
              I18n.t('exports.status.aborted') => 0,
              I18n.t('exports.status.canceled') => 0
            }
          )
        end

        context 'with aggregate_attribute "duration"' do
          let(:aggregate_operation) { 'average' }
          let(:aggregate_attribute) { 'duration' }

          it 'returns correct data' do
            is_expected.to eq(
              {
                I18n.t('exports.status.new') => 0,
                I18n.t('exports.status.pending') => 0,
                I18n.t('exports.status.successful') => 2700,
                I18n.t('exports.status.warning') => 0,
                I18n.t('exports.status.failed') => 3600,
                I18n.t('exports.status.running') => 0,
                I18n.t('exports.status.aborted') => 0,
                I18n.t('exports.status.canceled') => 0
              }
            )
          end
        end
      end
    end
  end
end
