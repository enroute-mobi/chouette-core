# frozen_string_literal: true

RSpec.describe Scope::Workbench do
  subject(:scope) { Scope::Workbench.new(workbench) }

  let(:context) do # rubocop:disable Metrics/BlockLength
    Chouette.create do # rubocop:disable Metrics/BlockLength
      workgroup do # rubocop:disable Metrics/BlockLength
        workbench :same_workgroup_workbench do
          document :document_other_workbench
        end

        workbench :workbench do # rubocop:disable Metrics/BlockLength
          document :document_company
          document :document_line
          document :document_stop_area
          document :document_unassociated

          company :company, documents: %i[document_company]

          network :network

          line :line, documents: %i[document_line document_other_workbench]

          stop_area :stop_area1, documents: %i[document_stop_area] do
            entrance :entrance
          end
          stop_area :stop_area2
          connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2

          shape :shape
          point_of_interest :point_of_interest

          referential :referential, lines: %i[line] do
            time_table :time_table,
                       dates_included: Time.zone.today,
                       periods: [Time.zone.yesterday..Time.zone.tomorrow]

            route :route, with_stops: false, line: :line do
              stop_point stop_area: :stop_area1
              stop_point stop_area: :stop_area2
              journey_pattern :journey_pattern, shape: :shape do
                vehicle_journey time_tables: %i[time_table]
              end
            end
          end
        end
      end

      workgroup do
        workbench :other_workbench do
          company
          network
          line
          stop_area :other_stop_area1 do
            entrance
          end
          stop_area :other_stop_area2
          connection_link departure: :other_stop_area1, arrival: :other_stop_area2
          shape
          point_of_interest
        end
      end
    end
  end
  let(:service_count) do
    ServiceCount.create!(
      line: context.line(:line),
      route: context.route(:route),
      journey_pattern: context.journey_pattern(:journey_pattern),
      date: Time.zone.today
    )
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  before { referential.switch }

  describe '#lines' do
    subject { scope.lines }

    it { is_expected.to match_array([context.line(:line)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line(:line)]) }
    end
  end

  describe '#companies' do
    subject { scope.companies }

    it { is_expected.to match_array([context.company(:company)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.company(:company)]) }
    end
  end

  describe '#networks' do
    subject { scope.networks }

    it { is_expected.to match_array([context.network(:network)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.network(:network)]) }
    end
  end

  describe '#stop_areas' do
    subject { scope.stop_areas }

    it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }
    end
  end

  describe '#entrances' do
    subject { scope.entrances }

    it { is_expected.to match_array([context.entrance(:entrance)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#connection_links' do
    subject { scope.connection_links }

    it { is_expected.to match_array([context.connection_link(:connection_link)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#shapes' do
    subject { scope.shapes }

    it { is_expected.to match_array([context.shape(:shape)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#point_of_interests' do
    subject { scope.point_of_interests }

    it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }
    end
  end

  describe '#documents' do
    subject { scope.documents }

    it do
      is_expected.to match_array(
        [
          context.document(:document_company),
          context.document(:document_line),
          context.document(:document_stop_area),
          context.document(:document_unassociated)
        ]
      )
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.document(:document_other_workbench)]) }
    end
  end

  %i[
    routes
    stop_points
    journey_patterns
    journey_pattern_stop_points
    vehicle_journeys
    vehicle_journey_at_stops
    time_tables
    time_table_periods
    time_table_dates
  ].each do |empty_method|
    describe "##{empty_method}" do
      subject { scope.send(empty_method) }

      it { is_expected.to be_empty }
    end
  end

  describe '#service_counts' do
    subject { scope.service_counts }

    before { service_count }

    it { is_expected.to be_empty }
  end
end

RSpec.describe Scope::Referential do
  subject(:scope) { Scope::Referential.new(workbench, referential) }

  let(:context) do # rubocop:disable Metrics/BlockLength
    Chouette.create do # rubocop:disable Metrics/BlockLength
      workgroup do # rubocop:disable Metrics/BlockLength
        workbench :same_workgroup_workbench do
          document :document_other_workbench
        end

        workbench :workbench do # rubocop:disable Metrics/BlockLength
          document :document_company
          document :document_line
          document :document_stop_area
          document :document_outside
          document :document_unassociated

          company :company, documents: %i[document_company]
          company :company_outside, documents: %i[document_outside]

          network :network
          network :network_outside

          line :line, company: :company, network: :network, documents: %i[document_line document_other_workbench]
          line :line_without_route
          line :line_outside, company: :company_outside, network: :network_outside, documents: %i[document_outside]

          stop_area :stop_area1, documents: %i[document_stop_area] do
            entrance :entrance
          end
          stop_area :stop_area2
          connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2
          stop_area :stop_area_outside1, documents: %i[document_outside] do
            entrance :entrance_outside
          end
          stop_area :stop_area_outside2
          connection_link :connection_link_outside, departure: :stop_area_outside1, arrival: :stop_area_outside2

          shape :shape
          shape :shape_outside
          point_of_interest :point_of_interest

          referential :referential, lines: %i[line line_without_route] do
            time_table :time_table,
                       dates_included: Time.zone.today,
                       periods: [Time.zone.yesterday..Time.zone.tomorrow]

            route :route, with_stops: false, line: :line do
              stop_point :stop_point1, stop_area: :stop_area1
              stop_point :stop_point2, stop_area: :stop_area2
              journey_pattern :journey_pattern, shape: :shape do
                vehicle_journey :vehicle_journey, time_tables: %i[time_table]
              end
            end
          end

          referential :same_workbench_referential

          referential lines: %i[line_outside] do
            time_table :other_time_table,
                       dates_included: Time.zone.today,
                       periods: [Time.zone.yesterday..Time.zone.tomorrow]

            route with_stops: false, line: :line do
              stop_point stop_area: :stop_area_outside1
              stop_point stop_area: :stop_area_outside2
              journey_pattern shape: :shape_outside do
                vehicle_journey time_tables: %i[other_time_table]
              end
            end
          end
        end
      end

      workgroup do
        workbench :other_workbench
      end
    end
  end
  let(:service_count) do
    ServiceCount.create!(
      line: context.line(:line),
      route: context.route(:route),
      journey_pattern: context.journey_pattern(:journey_pattern),
      date: Time.zone.today
    )
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  before { referential.switch }

  describe '#lines' do
    subject { scope.lines }

    it { is_expected.to match_array([context.line(:line), context.line(:line_without_route)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to match_array([be_a(Chouette::Line)]) }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line(:line), context.line(:line_without_route)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.line(:line), context.line(:line_without_route)]) }
    end
  end

  describe '#companies' do
    subject { scope.companies }

    it { is_expected.to match_array([context.company(:company)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.company(:company)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#networks' do
    subject { scope.networks }

    it { is_expected.to match_array([context.network(:network)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.network(:network)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#stop_areas' do
    subject { scope.stop_areas }

    it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#entrances' do
    subject { scope.entrances }

    it { is_expected.to match_array([context.entrance(:entrance)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.entrance(:entrance)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#connection_links' do
    subject { scope.connection_links }

    it { is_expected.to match_array([context.connection_link(:connection_link)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.connection_link(:connection_link)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#shapes' do
    subject { scope.shapes }

    it { is_expected.to match_array([context.shape(:shape)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.shape(:shape)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#point_of_interests' do
    subject { scope.point_of_interests }

    it { is_expected.to be_empty }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#documents' do
    subject { scope.documents }

    it do
      is_expected.to match_array(
        [
          context.document(:document_company),
          context.document(:document_line),
          context.document(:document_stop_area),
          context.document(:document_other_workbench)
        ]
      )
    end

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it do
        is_expected.to match_array(
          [
            context.document(:document_company),
            context.document(:document_line),
            context.document(:document_stop_area),
            context.document(:document_other_workbench)
          ]
        )
      end
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#routes' do
    subject { scope.routes }

    it { is_expected.to match_array([context.route(:route)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.route(:route)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.route(:route)]) }
    end
  end

  describe '#stop_points' do
    subject { scope.stop_points }

    it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }
    end
  end

  describe '#journey_patterns' do
    subject { scope.journey_patterns }

    it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }
    end
  end

  describe '#journey_pattern_stop_points' do
    subject { scope.journey_pattern_stop_points }

    it do
      is_expected.to match_array(
        [
          have_attributes(stop_point: context.stop_point(:stop_point1)),
          have_attributes(stop_point: context.stop_point(:stop_point2))
        ]
      )
    end

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end
  end

  describe '#vehicle_journeys' do
    subject { scope.vehicle_journeys }

    it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }
    end
  end

  describe '#vehicle_journey_at_stops' do
    subject { scope.vehicle_journey_at_stops }

    it do
      is_expected.to match_array(
        [
          have_attributes(stop_point: context.stop_point(:stop_point1)),
          have_attributes(stop_point: context.stop_point(:stop_point2))
        ]
      )
    end

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end
  end

  describe '#time_tables' do
    subject { scope.time_tables }

    it { is_expected.to match_array([context.time_table(:time_table)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.time_table(:time_table)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.time_table(:time_table)]) }
    end
  end

  describe '#time_table_periods' do
    subject { scope.time_table_periods }

    it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod)]) }
    end
  end

  describe '#time_table_dates' do
    subject { scope.time_table_dates }

    it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }
    end
  end

  describe '#service_counts' do
    subject { scope.service_counts }

    before { service_count }

    it { is_expected.to match_array([service_count]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([service_count]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([service_count]) }
    end
  end
end

RSpec.describe Scope::Owned do
  subject(:scope) { Scope::Owned.new(parent_scope, workbench) }

  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  before { referential.switch }

  context 'of Scope::Workbench' do
    let(:parent_scope) { Scope::Workbench.new(context.workbench(:workbench)) }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do # rubocop:disable Metrics/BlockLength
          workbench :workbench do # rubocop:disable Metrics/BlockLength
            document :document_company
            document :document_line
            document :document_stop_area
            document :document_unassociated

            company :company, documents: %i[document_company]

            network :network

            line :line, documents: %i[document_line]

            stop_area :stop_area1, documents: %i[document_stop_area] do
              entrance :entrance
            end
            stop_area :stop_area2
            connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2

            shape :shape
            point_of_interest :point_of_interest

            referential :referential, lines: %i[line] do
              time_table :time_table,
                         dates_included: Time.zone.today,
                         periods: [Time.zone.yesterday..Time.zone.tomorrow]

              route :route, with_stops: false, line: :line do
                stop_point stop_area: :stop_area1
                stop_point stop_area: :stop_area2
                journey_pattern :journey_pattern, shape: :shape do
                  vehicle_journey time_tables: %i[time_table]
                end
              end
            end
          end

          workbench :same_workgroup_workbench
        end
      end
    end
    let(:service_count) do
      ServiceCount.create!(
        line: context.line(:line),
        route: context.route(:route),
        journey_pattern: context.journey_pattern(:journey_pattern),
        date: Time.zone.today
      )
    end

    describe '#lines' do
      subject { scope.lines }

      it { is_expected.to match_array([context.line(:line)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#companies' do
      subject { scope.companies }

      it { is_expected.to match_array([context.company(:company)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#networks' do
      subject { scope.networks }

      it { is_expected.to match_array([context.network(:network)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      it { is_expected.to match_array([context.entrance(:entrance)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      it { is_expected.to match_array([context.connection_link(:connection_link)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#shapes' do
      subject { scope.shapes }

      it { is_expected.to match_array([context.shape(:shape)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#documents' do
      subject { scope.documents }

      it do
        is_expected.to match_array(
          [
            context.document(:document_company),
            context.document(:document_line),
            context.document(:document_stop_area),
            context.document(:document_unassociated)
          ]
        )
      end

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    %i[
      routes
      stop_points
      journey_patterns
      journey_pattern_stop_points
      vehicle_journeys
      vehicle_journey_at_stops
      time_tables
      time_table_periods
      time_table_dates
    ].each do |empty_method|
      describe "##{empty_method}" do
        subject { scope.send(empty_method) }

        it { is_expected.to be_empty }
      end
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      before { service_count }

      it { is_expected.to be_empty }
    end
  end

  context 'of Scope::Referential' do
    let(:parent_scope) { Scope::Referential.new(context.workbench(:workbench), context.referential(:referential)) }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do # rubocop:disable Metrics/BlockLength
          workbench :same_workgroup_workbench do
            document :document_other_workbench
          end

          workbench :workbench do # rubocop:disable Metrics/BlockLength
            document :document_company
            document :document_line
            document :document_stop_area
            document :document_outside
            document :document_unassociated

            company :company, documents: %i[document_company]
            company :company_outside, documents: %i[document_outside]

            network :network
            network :network_outside

            line :line, company: :company, network: :network, documents: %i[document_line document_other_workbench]
            line :line_without_route
            line :line_outside, company: :company_outside, network: :network_outside, documents: %i[document_outside]

            stop_area :stop_area1, documents: %i[document_stop_area] do
              entrance :entrance
            end
            stop_area :stop_area2
            connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2
            stop_area :stop_area_outside1, documents: %i[document_outside] do
              entrance :entrance_outside
            end
            stop_area :stop_area_outside2
            connection_link :connection_link_outside, departure: :stop_area_outside1, arrival: :stop_area_outside2

            shape :shape
            shape :shape_outside
            point_of_interest :point_of_interest

            referential :referential, lines: %i[line line_without_route] do
              time_table :time_table,
                         dates_included: Time.zone.today,
                         periods: [Time.zone.yesterday..Time.zone.tomorrow]

              route :route, with_stops: false, line: :line do
                stop_point :stop_point1, stop_area: :stop_area1
                stop_point :stop_point2, stop_area: :stop_area2
                journey_pattern :journey_pattern, shape: :shape do
                  vehicle_journey :vehicle_journey, time_tables: %i[time_table]
                end
              end
            end
          end
        end
      end
    end
    let(:service_count) do
      ServiceCount.create!(
        line: context.line(:line),
        route: context.route(:route),
        journey_pattern: context.journey_pattern(:journey_pattern),
        date: Time.zone.today
      )
    end

    describe '#lines' do
      subject { scope.lines }

      it { is_expected.to match_array([context.line(:line), context.line(:line_without_route)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#companies' do
      subject { scope.companies }

      it { is_expected.to match_array([context.company(:company)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#networks' do
      subject { scope.networks }

      it { is_expected.to match_array([context.network(:network)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      it { is_expected.to match_array([context.stop_area(:stop_area1), context.stop_area(:stop_area2)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      it { is_expected.to match_array([context.entrance(:entrance)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      it { is_expected.to match_array([context.connection_link(:connection_link)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#shapes' do
      subject { scope.shapes }

      it { is_expected.to match_array([context.shape(:shape)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      it { is_expected.to be_empty }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#documents' do
      subject { scope.documents }

      it do
        is_expected.to match_array(
          [
            context.document(:document_company),
            context.document(:document_line),
            context.document(:document_stop_area)
          ]
        )
      end

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.document(:document_other_workbench)]) }
      end
    end

    describe '#routes' do
      subject { scope.routes }

      it { is_expected.to match_array([context.route(:route)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.route(:route)]) }
      end
    end

    describe '#stop_points' do
      subject { scope.stop_points }

      it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }
      end
    end

    describe '#journey_patterns' do
      subject { scope.journey_patterns }

      it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }
      end
    end

    describe '#journey_pattern_stop_points' do
      subject { scope.journey_pattern_stop_points }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it do
          is_expected.to match_array(
            [
              have_attributes(stop_point: context.stop_point(:stop_point1)),
              have_attributes(stop_point: context.stop_point(:stop_point2))
            ]
          )
        end
      end
    end

    describe '#vehicle_journeys' do
      subject { scope.vehicle_journeys }

      it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }
      end
    end

    describe '#vehicle_journey_at_stops' do
      subject { scope.vehicle_journey_at_stops }

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it do
          is_expected.to match_array(
            [
              have_attributes(stop_point: context.stop_point(:stop_point1)),
              have_attributes(stop_point: context.stop_point(:stop_point2))
            ]
          )
        end
      end
    end

    describe '#time_tables' do
      subject { scope.time_tables }

      it { is_expected.to match_array([context.time_table(:time_table)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([context.time_table(:time_table)]) }
      end
    end

    describe '#time_table_periods' do
      subject { scope.time_table_periods }

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod)]) }
      end
    end

    describe '#time_table_dates' do
      subject { scope.time_table_dates }

      it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }
      end
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      before { service_count }

      it { is_expected.to match_array([service_count]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to match_array([service_count]) }
      end
    end
  end
end
