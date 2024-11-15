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

    let(:search) { described_class.new(zip_code: '44300', per_page: 1, page: 1) }
    let(:workbench_scope) { Scope::Workbench.new(context.workbench) }
    let(:referential_scope) { Scope::Referential.new(context.workbench, context.referential) }
    let(:initial_scope) { referential_scope }

    before { context.referential.switch }

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          line :line_match
          line :line_no_match
          line :line_without_route

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match line_without_route] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route :route_no_match, with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.line(:line_match)]) }
      end
    end

    describe '#line_groups' do
      subject { scope.line_groups }

      let(:context) do
        Chouette.create do
          line :line_match
          line :line_no_match

          line_group :line_group_match, lines: %i[line_match]
          line_group :line_group_no_match, lines: %i[line_no_match]

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.line_group(:line_group_match)]) }
      end
    end

    describe '#line_notices' do
      subject { scope.line_notices }

      let(:context) do
        Chouette.create do
          line :line_match
          line :line_no_match

          line_notice :line_notice_match, lines: %i[line_match]
          line_notice :line_notice_no_match, lines: %i[line_no_match]

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.line_notice(:line_notice_match)]) }
      end
    end

    describe '#companies' do
      subject { scope.companies }

      let(:context) do
        Chouette.create do
          company :company_match
          company :company_no_match

          line :line_match, company: :company_match
          line :line_no_match, company: :company_no_match

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.company(:company_match)]) }
      end
    end

    describe '#networks' do
      subject { scope.networks }

      let(:context) do
        Chouette.create do
          network :network_match
          network :network_no_match

          line :line_match, network: :network_match
          line :line_no_match, network: :network_no_match

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.network(:network_match)]) }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000
          stop_area :stop_area_outside, zip_code: 44_300

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.stop_area(:stop_area_match), context.stop_area(:stop_area_outside)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.stop_area(:stop_area_match)]) }
      end
    end

    describe '#stop_area_groups' do
      subject { scope.stop_area_groups }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000
          stop_area :stop_area_outside, zip_code: 44_300

          stop_area_group :stop_area_group_match, stop_areas: %i[stop_area_match]
          stop_area_group :stop_area_group_no_match, stop_areas: %i[stop_area_no_match]
          stop_area_group :stop_area_group_outside, stop_areas: %i[stop_area_outside]

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.stop_area_group(:stop_area_group_match),
              context.stop_area_group(:stop_area_group_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to match_array([context.stop_area_group(:stop_area_group_match)]) }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300 do
            entrance :entrance_match
          end
          stop_area :stop_area_no_match, zip_code: 0o0000 do
            entrance :entrance_no_match
          end
          stop_area :stop_area_outside, zip_code: 44_300 do
            entrance :entrance_outside
          end

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.entrance(:entrance_match), context.entrance(:entrance_outside)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.entrance(:entrance_match)]) }
      end
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match1, zip_code: 44_300
          stop_area :stop_area_match2, zip_code: 44_300
          connection_link :connection_link_match, departure: :stop_area_match1, arrival: :stop_area_match2
          stop_area :stop_area_no_match, zip_code: 0o0000 do
            entrance :entrance_no_match
          end
          connection_link :connection_link_no_match, departure: :stop_area_match1, arrival: :stop_area_no_match
          stop_area :stop_area_outside, zip_code: 44_300
          connection_link :connection_link_outside, departure: :stop_area_match1, arrival: :stop_area_outside

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match1
              stop_point stop_area: :stop_area_match2
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.connection_link(:connection_link_match),
              context.connection_link(:connection_link_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to match_array([context.connection_link(:connection_link_match)]) }
      end
    end

    describe '#shapes' do
      subject { scope.shapes }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          shape :shape_match
          shape :shape_no_match

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              journey_pattern shape: :shape_match
            end
            route with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              journey_pattern shape: :shape_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.shape(:shape_match)]) }
      end
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300

          point_of_interest :point_of_interest_match

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.point_of_interest(:point_of_interest_match)]) }
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#service_facility_sets' do
      subject { scope.service_facility_sets }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          service_facility_set :service_facility_set_match
          service_facility_set :service_facility_set_no_match

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              vehicle_journey service_facility_sets: %i[service_facility_set_match]
            end
            route with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              vehicle_journey service_facility_sets: %i[service_facility_set_no_match]
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.service_facility_set(:service_facility_set_match)]) }
      end
    end

    describe '#accessibility_assessments' do
      subject { scope.accessibility_assessments }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300

          accessibility_assessment :accessibility_assessment

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.accessibility_assessment(:accessibility_assessment)]) }
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#fare_zones' do
      subject { scope.fare_zones }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000
          stop_area :stop_area_outside, zip_code: 44_300

          fare_zone :fare_zone_match, stop_areas: %i[stop_area_match]
          fare_zone :fare_zone_no_match, stop_areas: %i[stop_area_no_match]
          fare_zone :fare_zone_outside, stop_areas: %i[stop_area_outside]

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it { is_expected.to match_array([context.fare_zone(:fare_zone_match), context.fare_zone(:fare_zone_outside)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.fare_zone(:fare_zone_match)]) }
      end
    end

    describe '#line_routing_constraint_zones' do
      subject { scope.line_routing_constraint_zones }

      let(:context) do # rubocop:disable Metrics/BlockLength
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000
          stop_area :stop_area_outside, zip_code: 44_300

          line :line_match
          line :line_no_match

          line_routing_constraint_zone :line_routing_constraint_zone_match,
                                       lines: %i[line_match], stop_areas: %i[stop_area_match]
          line_routing_constraint_zone :line_routing_constraint_zone_line_no_match,
                                       lines: %i[line_no_match], stop_areas: %i[stop_area_match]
          line_routing_constraint_zone :line_routing_constraint_zone_stop_area_no_match,
                                       lines: %i[line_match], stop_areas: %i[stop_area_no_match]
          line_routing_constraint_zone :line_routing_constraint_zone_stop_area_outside,
                                       lines: %i[line_no_match], stop_areas: %i[stop_area_outside]
          line_routing_constraint_zone :line_routing_constraint_zone_no_match,
                                       lines: %i[line_no_match], stop_areas: %i[stop_area_no_match]

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.line_routing_constraint_zone(:line_routing_constraint_zone_match),
              context.line_routing_constraint_zone(:line_routing_constraint_zone_line_no_match),
              context.line_routing_constraint_zone(:line_routing_constraint_zone_stop_area_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.line_routing_constraint_zone(:line_routing_constraint_zone_match),
              context.line_routing_constraint_zone(:line_routing_constraint_zone_line_no_match),
              context.line_routing_constraint_zone(:line_routing_constraint_zone_stop_area_no_match)
            ]
          )
        end
      end
    end

    describe '#documents' do
      subject { scope.documents }

      let(:context) do
        Chouette.create do
          document :document_company_match
          document :document_line_match
          document :document_stop_area_match
          document :document_stop_area_outside
          document :document_no_match

          company :company_match, documents: %i[document_company_match]
          company :company_no_match, documents: %i[document_no_match]

          line :line_match, company: :company_match, documents: %i[document_line_match]
          line :line_no_match, company: :company_no_match, documents: %i[document_no_match]

          stop_area :stop_area_match, zip_code: 44_300, documents: %i[document_stop_area_match]
          stop_area :stop_area_no_match, zip_code: 0o0000, documents: %i[document_no_match]
          stop_area :stop_area_outside, zip_code: 44_300, documents: %i[document_stop_area_outside]

          referential lines: %i[line_match line_no_match] do
            route with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_no_match
            end
            route with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      context 'in workbench' do
        let(:initial_scope) { workbench_scope }

        it do
          is_expected.to match_array(
            [
              context.document(:document_stop_area_match),
              context.document(:document_stop_area_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.document(:document_company_match),
              context.document(:document_line_match),
              context.document(:document_stop_area_match)
            ]
          )
        end
      end
    end

    describe '#routes' do
      subject { scope.routes }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential do
            route :route_match, with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
            end
            route :route_no_match, with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
            end
          end
        end
      end

      it { is_expected.to match_array([context.route(:route_match)]) }
    end

    describe '#stop_points' do
      subject { scope.stop_points }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential do
            route with_stops: false do
              stop_point :stop_point_match, stop_area: :stop_area_match
              stop_point :stop_point_no_match, stop_area: :stop_area_no_match
            end
          end
        end
      end

      it do
        is_expected.to match_array([context.stop_point(:stop_point_match)])
      end
    end

    describe '#journey_patterns' do
      subject { scope.journey_patterns }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              journey_pattern :journey_pattern_match
            end
            route with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              journey_pattern :journey_pattern_no_match
            end
          end
        end
      end

      it { is_expected.to match_array([context.journey_pattern(:journey_pattern_match)]) }
    end

    describe '#vehicle_journeys' do
      subject { scope.vehicle_journeys }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              vehicle_journey :vehicle_journey_match
            end
            route with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              vehicle_journey :vehicle_journey_no_match
            end
          end
        end
      end

      it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey_match)]) }
    end

    describe '#time_tables' do
      subject { scope.time_tables }

      let(:context) do
        Chouette.create do
          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential do
            time_table :time_table_match
            time_table :time_table_no_match

            route with_stops: false do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              vehicle_journey :vehicle_journey_match1, time_tables: %i[time_table_match]
            end
            route with_stops: false do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              vehicle_journey :vehicle_journey_no_match, time_tables: %i[time_table_no_match]
            end
          end
        end
      end

      it { is_expected.to match_array([context.time_table(:time_table_match)]) }
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      let(:context) do
        Chouette.create do
          line :line_match
          line :line_no_match

          stop_area :stop_area_match, zip_code: 44_300
          stop_area :stop_area_no_match, zip_code: 0o0000

          referential lines: %i[line_match line_no_match] do
            route :route_match, with_stops: false, line: :line_match do
              stop_point stop_area: :stop_area_match
              stop_point stop_area: :stop_area_match
              journey_pattern :journey_pattern_match
            end
            route :route_no_match, with_stops: false, line: :line_no_match do
              stop_point stop_area: :stop_area_no_match
              stop_point stop_area: :stop_area_no_match
              journey_pattern :journey_pattern_no_match
            end
          end
        end
      end
      let!(:service_count_match) do
        ServiceCount.create!(
          line: context.line(:line_match),
          route: context.route(:route_match),
          journey_pattern: context.journey_pattern(:journey_pattern_match),
          date: Time.zone.today
        )
      end
      let!(:service_count_no_match) do
        ServiceCount.create!(
          line: context.line(:line_no_match),
          route: context.route(:route_no_match),
          journey_pattern: context.journey_pattern(:journey_pattern_no_match),
          date: Time.zone.today
        )
      end

      it { is_expected.to match_array([service_count_match]) }
    end
  end
end
