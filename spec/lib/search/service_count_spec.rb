# frozen_string_literal: true

RSpec.describe Search::ServiceCount, type: :model do
  subject(:search) { described_class.new }

  describe 'validation' do
    context 'when chart_type is present' do
      before { search.chart_type = 'line' }

      it { is_expected.to allow_value('date').for(:group_by_attribute) }
      it { is_expected.to allow_value('date_by_week').for(:group_by_attribute) }
      it { is_expected.to allow_value('date_by_month').for(:group_by_attribute) }
      it { is_expected.to allow_value('date_day_of_week').for(:group_by_attribute) }
    end
  end

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(ServiceCount) }
  end

  describe '#query' do
    describe 'build' do
      let(:scope) { double }
      let(:query) { Query::Mock.new(scope) }
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              company :company1
              company :company2

              network :network1
              network :network2

              line :line1
              line :line2
            end
          end

          workgroup do
            workbench :other_workbench do
              company :other_company

              network :other_network

              line :other_line
            end
          end
        end
      end

      before do
        search.workbench = context.workbench(:workbench)
        allow(Query::ServiceCount).to receive(:new).and_return(query)
      end

      it 'uses Search line_ids' do
        search.line_ids = %i[line1 line2 other_line].map { |l| context.line(l).id }
        expect(query).to(
          receive(:line_ids).with(%i[line1 line2].map { |l| context.line(l) }).and_return(query)
        )
        search.query(scope)
      end

      it 'uses Search company_ids' do
        search.company_ids = %i[company1 company2 other_company].map { |c| context.company(c).id }
        expect(query).to(
          receive(:company_ids).with(%i[company1 company2].map { |c| context.company(c) }).and_return(query)
        )
        search.query(scope)
      end

      it 'uses Search network_ids' do
        search.network_ids = %i[network1 network2 other_network].map { |n| context.network(n) }
        expect(query).to(
          receive(:network_ids).with(%i[network1 network2].map { |n| context.network(n) }).and_return(query)
        )
        search.query(scope)
      end

      it 'uses Search transport_modes' do
        search.transport_modes = %w[bus air]
        expect(query).to receive(:transport_modes).with(%w[bus air]).and_return(query)
        search.query(scope)
      end

      it 'uses Search period' do
        allow(search).to receive(:period).and_return(double)
        expect(query).to receive(:in_period).with(search.period).and_return(query)
        search.query(scope)
      end

      it 'uses Search days_of_week' do
        search.days_of_week = Cuckoo::DaysOfWeek.new(tuesday: true, thursday: true)
        expect(query).to receive(:days_of_week).with(search.days_of_week).and_return(query)
        search.query(scope)
      end
    end
  end

  describe '#chart' do
    subject(:chart) { search.chart(scope) }

    let(:date) { Time.zone.parse('2024-08-20T00:00:00') }
    let(:context) do # rubocop:disable Metrics/BlockLength
      context = Chouette.create do # rubocop:disable Metrics/BlockLength
        workbench do
          company :company1
          company :company2

          network :network1
          network :network2

          line :line, company: :company1, network: :network1, transport_mode: 'bus'
          line :company_line, company: :company2, transport_mode: 'bus'
          line :network_line, company: :company1, network: :network2, transport_mode: 'bus'
          line :transport_mode_line, company: :company1, transport_mode: 'air'

          referential lines: %i[line company_line network_line transport_mode_line] do
            route :line_route, line: :line, wayback: 'inbound' do
              journey_pattern :line_journey_pattern
            end

            route :company_route, line: :company_line, wayback: 'inbound' do
              journey_pattern :company_journey_pattern
            end

            route :network_route, line: :network_line, wayback: 'inbound' do
              journey_pattern :network_journey_pattern
            end

            route :transport_mode_route, line: :transport_mode_line, wayback: 'inbound' do
              journey_pattern :transport_mode_journey_pattern
            end

            route :wayback_route, line: :line, wayback: 'outbound' do
              journey_pattern :wayback_journey_pattern
            end
          end
        end
      end
      context.referential.switch
      # rubocop:disable Layout/LineLength
      ServiceCount.create!(line: context.line(:line), route: context.route(:line_route), journey_pattern: context.journey_pattern(:line_journey_pattern), date: date, count: 1)
      ServiceCount.create!(line: context.line(:company_line), route: context.route(:company_route), journey_pattern: context.journey_pattern(:company_journey_pattern), date: date, count: 2)
      ServiceCount.create!(line: context.line(:network_line), route: context.route(:network_route), journey_pattern: context.journey_pattern(:network_journey_pattern), date: date - 1.day, count: 4)
      ServiceCount.create!(line: context.line(:transport_mode_line), route: context.route(:transport_mode_route), journey_pattern: context.journey_pattern(:transport_mode_journey_pattern), date: date - 1.day, count: 8)
      ServiceCount.create!(line: context.line(:line), route: context.route(:wayback_route), journey_pattern: context.journey_pattern(:wayback_journey_pattern), date: date - 2.days, count: 16)
      # rubocop:enable Layout/LineLength
      context
    end

    let(:search) do
      described_class.new(
        workbench: context.workbench,
        chart_type: 'line',
        group_by_attribute: group_by_attribute,
        top_count: 10
      )
    end
    let(:scope) { context.referential.service_counts }

    describe '#data' do
      subject { chart.data }

      context 'with date' do
        let(:group_by_attribute) { 'date' }

        it 'returns correct data' do
          Timecop.travel(date + 1.day)
          is_expected.to eq(
            {
              Date.parse('2024-08-11') => 0,
              Date.parse('2024-08-12') => 0,
              Date.parse('2024-08-13') => 0,
              Date.parse('2024-08-14') => 0,
              Date.parse('2024-08-15') => 0,
              Date.parse('2024-08-16') => 0,
              Date.parse('2024-08-17') => 0,
              Date.parse('2024-08-18') => 16,
              Date.parse('2024-08-19') => 12,
              Date.parse('2024-08-20') => 3
            }
          )
        ensure
          Timecop.return
        end

        context 'with filter on period' do
          before do
            search.start_date = Date.parse('2024-08-18')
            search.end_date = Date.parse('2024-08-20')
          end

          it 'returns correct data' do
            is_expected.to eq(
              {
                Date.parse('2024-08-18') => 16,
                Date.parse('2024-08-19') => 12,
                Date.parse('2024-08-20') => 3
              }
            )
          end
        end
      end

      context 'with line_id' do
        let(:group_by_attribute) { 'line_id' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              context.line(:line).name => 17,
              context.line(:company_line).name => 2,
              context.line(:network_line).name => 4,
              context.line(:transport_mode_line).name => 8
            }
          )
        end
      end

      context 'with company_id' do
        let(:group_by_attribute) { 'company_id' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              context.company(:company1).name => 29,
              context.company(:company2).name => 2
            }
          )
        end
      end

      context 'with network_id' do
        let(:group_by_attribute) { 'network_id' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              context.network(:network1).name => 17,
              context.network(:network2).name => 4,
              I18n.t('none') => 10
            }
          )
        end
      end

      context 'with transport_mode' do
        let(:group_by_attribute) { 'transport_mode' }

        it 'returns correct data' do
          is_expected.to eq(
            Chouette::TransportMode.modes.map { |tm| [tm.mode_human_name, 0] }.to_h.merge(
              {
                Chouette::TransportMode.new('bus').mode_human_name => 23,
                Chouette::TransportMode.new('air').mode_human_name => 8
              }
            )
          )
        end
      end

      context 'with route_wayback' do
        let(:group_by_attribute) { 'route_wayback' }

        it 'returns correct data' do
          is_expected.to eq(
            {
              Chouette::Route.wayback.find_value('inbound').text => 15,
              Chouette::Route.wayback.find_value('outbound').text => 16
            }
          )
        end
      end
    end
  end
end
