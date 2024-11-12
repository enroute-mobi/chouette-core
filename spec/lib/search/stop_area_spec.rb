# frozen_string_literal: true

RSpec.describe Search::StopArea do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Chouette::StopArea) }
  end

  describe '#search' do
    let!(:context) do
      Chouette.create do
        stop_area :first, name: '1'
        stop_area :second, name: '2'
        stop_area :last, name: '3'
      end
    end

    let(:first) { context.stop_area :first }
    let(:second) { context.stop_area :second }
    let(:last) { context.stop_area :last }

    let(:scope) { Chouette::StopArea.where(name: %w[1 2 3]) }

    subject { search.search(scope) }

    context 'search with pagination' do
      let(:search) { described_class.new(per_page: 2, page: 1) }

      it 'returns first 2 stop areas from the given scope' do
        is_expected.to match_array([first, second])
      end
    end

    context 'search without pagination' do
      let(:search) { described_class.new(per_page: 2, page: 1).without_pagination }

      it 'returns all stop areas from the given scope' do
        is_expected.to match_array([first, second, last])
      end
    end

    context 'search with order and pagination' do
      let(:search) { described_class.new(per_page: 2, page: 1, order: { name: :desc }) }

      it 'returns 2 stop areas with order for the name attribute from the given scope' do
        is_expected.to eq [last, second]
      end
    end

    context 'search with order' do
      let(:search) { described_class.new(order: { name: :desc }) }

      it 'returns all stop areas without order for the name attribute from the given scope' do
        is_expected.to eq [last, second, first]
      end
    end

    context 'search without order and without pagination' do
      let(:search) do
        described_class.new(per_page: 2, page: 1, order: { name: :desc }).without_order.without_pagination
      end

      it 'returns all stop areas without order for the name attribute from the given scope' do
        is_expected.to eq [first, second, last]
      end
    end
  end

  describe '#scope' do
    subject(:scope) { search.scope(initial_scope) }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        document :document_company_match1
        document :document_company_match2
        document :document_company_no_match
        document :document_line_match1
        document :document_line_match2
        document :document_line_no_match
        document :document_stop_area_match1
        document :document_stop_area_match2
        document :document_stop_area_no_match

        company :company_match1, documents: %i[document_company_match1]
        company :company_match2, documents: %i[document_company_match2]
        company :company_no_match, documents: %i[document_company_no_match]

        network :network_match1
        network :network_match2
        network :network_no_match

        line :line_match1, company: :company_match1, network: :network_match1, documents: %i[document_line_match1]
        line :line_match2, company: :company_match2, network: :network_match2, documents: %i[document_line_match2]
        line :line_no_match,
             company: :company_no_match,
             network: :network_no_match,
             documents: %i[document_line_no_match]
        line :line_without_route, transport_mode: 'bus'

        line_group :line_group_match1, lines: %i[line_match1]
        line_group :line_group_match2, lines: %i[line_match2]
        line_group :line_group_no_match, lines: %i[line_no_match]

        stop_area :stop_area_match1, zip_code: 44_300, documents: %i[document_stop_area_match1] do
          entrance :entrance_match1
        end
        stop_area :stop_area_match2, zip_code: 44_300, documents: %i[document_stop_area_match2] do
          entrance :entrance_match2
        end
        connection_link :connection_link_match, departure: :stop_area_match1, arrival: :stop_area_match2
        stop_area :stop_area_no_match, zip_code: 0o0000, documents: %i[document_stop_area_no_match] do
          entrance :entrance_no_match
        end
        connection_link :connection_link_no_match, departure: :stop_area_match1, arrival: :stop_area_no_match
        stop_area :stop_area_outside, zip_code: 44_300

        stop_area_group :stop_area_group_match1, stop_areas: %i[stop_area_match1]
        stop_area_group :stop_area_group_match2, stop_areas: %i[stop_area_match2]
        stop_area_group :stop_area_group_no_match, stop_areas: %i[stop_area_no_match]

        shape_provider do
          shape :shape_match1
          point_of_interest :point_of_interest_match1
        end
        shape_provider do
          shape :shape_match2
          point_of_interest :point_of_interest_match2
        end
        shape_provider do
          shape :shape_no_match
          point_of_interest :point_of_interest_no_match
        end

        fare_zone :fare_zone_match1, stop_areas: %i[stop_area_match1]
        fare_zone :fare_zone_match2, stop_areas: %i[stop_area_match2]
        fare_zone :fare_zone_no_match, stop_areas: %i[stop_area_no_match]

        referential lines: %i[line_match1 line_match2 line_no_match line_without_route] do
          time_table :time_table_match1
          time_table :time_table_match2
          time_table :time_table_no_match

          route :route_match1, with_stops: false, line: :line_match1 do
            stop_point :stop_point_match1, stop_area: :stop_area_match1
            stop_point
            journey_pattern :journey_pattern_match1, shape: :shape_match1 do
              vehicle_journey :vehicle_journey_match1, time_tables: %i[time_table_match1]
            end
          end
          route :route_match2, with_stops: false, line: :line_match2 do
            stop_point :stop_point_match2, stop_area: :stop_area_match2
            stop_point
            journey_pattern :journey_pattern_match2, shape: :shape_match2 do
              vehicle_journey :vehicle_journey_match2, time_tables: %i[time_table_match2]
            end
          end
          route :route_no_match, with_stops: false, line: :line_no_match do
            stop_point :stop_point_no_match, stop_area: :stop_area_no_match
            stop_point
            journey_pattern :journey_pattern_no_match, shape: :shape_no_match do
              vehicle_journey :vehicle_journey_no_match, time_tables: %i[time_table_no_match]
            end
          end
        end
      end
    end

    let(:service_count_match1) do
      ServiceCount.create!(
        line: context.line(:line_match1),
        route: context.route(:route_match1),
        journey_pattern: context.journey_pattern(:journey_pattern_match1),
        date: Time.zone.today
      )
    end
    let(:service_count_match2) do
      ServiceCount.create!(
        line: context.line(:line_match2),
        route: context.route(:route_match1),
        journey_pattern: context.journey_pattern(:journey_pattern_match1),
        date: Time.zone.today
      )
    end
    let(:service_count_no_match) do
      ServiceCount.create!(
        line: context.line(:line_no_match),
        route: context.route(:route_match1),
        journey_pattern: context.journey_pattern(:journey_pattern_match1),
        date: Time.zone.today
      )
    end
    let(:service_counts) { [service_count_match1, service_count_match2, service_count_no_match] }

    let(:search) { described_class.new(zip_code: '44300', per_page: 1, page: 1) }
    let(:workbench_scope) { Scope::Workbench.new(context.workbench) }
    let(:referential_scope) { Scope::Referential.new(context.workbench, context.referential) }
    let(:initial_scope) { referential_scope }

    before { context.referential.switch }

    describe '#lines' do
      subject { scope.lines }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.line(:line_match1), context.line(:line_match2)]) }
      end
    end

    describe '#line_groups' do
      subject { scope.line_groups }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.line_group(:line_group_match1),
              context.line_group(:line_group_match2)
            ]
          )
        end
      end
    end

    describe '#companies' do
      subject { scope.companies }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.company(:company_match1), context.company(:company_match2)]) }
      end
    end

    describe '#networks' do
      subject { scope.networks }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.network(:network_match1), context.network(:network_match2)]) }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.stop_area(:stop_area_match1),
              context.stop_area(:stop_area_match2),
              context.stop_area(:stop_area_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to match_array([context.stop_area(:stop_area_match1), context.stop_area(:stop_area_match2)]) }
      end
    end

    describe '#stop_area_groups' do
      subject { scope.stop_area_groups }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.stop_area_group(:stop_area_group_match1),
              context.stop_area_group(:stop_area_group_match2)
            ]
          )
        end
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.stop_area_group(:stop_area_group_match1),
              context.stop_area_group(:stop_area_group_match2)
            ]
          )
        end
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.entrance(:entrance_match1),
              context.entrance(:entrance_match2)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to match_array([context.entrance(:entrance_match1), context.entrance(:entrance_match2)]) }
      end
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.connection_link(:connection_link_match)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.connection_link(:connection_link_match)]) }
      end
    end

    describe '#shapes' do
      subject { scope.shapes }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.shape(:shape_match1), context.shape(:shape_match2)]) }
      end
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.point_of_interest(:point_of_interest_match1),
              context.point_of_interest(:point_of_interest_match2),
              context.point_of_interest(:point_of_interest_no_match)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#fare_zones' do
      subject { scope.fare_zones }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.fare_zone(:fare_zone_match1), context.fare_zone(:fare_zone_match2)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.fare_zone(:fare_zone_match1), context.fare_zone(:fare_zone_match2)]) }
      end
    end

    describe '#documents' do
      subject { scope.documents }

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.document(:document_stop_area_match1),
              context.document(:document_stop_area_match2)
            ]
          )
        end
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.document(:document_company_match1),
              context.document(:document_company_match2),
              context.document(:document_line_match1),
              context.document(:document_line_match2),
              context.document(:document_stop_area_match1),
              context.document(:document_stop_area_match2)
            ]
          )
        end
      end
    end

    describe '#routes' do
      subject { scope.routes }

      it { is_expected.to match_array([context.route(:route_match1), context.route(:route_match2)]) }
    end

    describe '#stop_points' do
      subject { scope.stop_points }

      it do
        is_expected.to match_array([context.stop_point(:stop_point_match1), context.stop_point(:stop_point_match2)])
      end
    end

    describe '#journey_patterns' do
      subject { scope.journey_patterns }

      it do
        is_expected.to match_array(
          [context.journey_pattern(:journey_pattern_match1), context.journey_pattern(:journey_pattern_match2)]
        )
      end
    end

    describe '#vehicle_journeys' do
      subject { scope.vehicle_journeys }

      it do
        is_expected.to match_array(
          [context.vehicle_journey(:vehicle_journey_match1), context.vehicle_journey(:vehicle_journey_match2)]
        )
      end
    end

    describe '#time_tables' do
      subject { scope.time_tables }

      it do
        is_expected.to match_array(
          [
            context.time_table(:time_table_match1),
            context.time_table(:time_table_match2)
          ]
        )
      end
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      before { service_counts }

      it { is_expected.to match_array([service_count_match1, service_count_match2]) }
    end
  end
end
