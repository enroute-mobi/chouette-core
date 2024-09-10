# frozen_string_literal: true

RSpec.describe Macro::Context::SavedSearch::Run do
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:macro_list) do
    Macro::List.create! name: 'Macro List', workbench: workbench
  end
  let(:macro_context) do
    Macro::Context::SavedSearch.create!(
      name: 'Macro Context Saved Search',
      macro_list: macro_list,
      saved_search_id: saved_search_id
    )
  end
  let!(:macro_dummy) do
    Macro::Dummy.create(
      name: 'Macro dummy',
      macro_context: macro_context,
      target_model: 'StopArea',
      position: 0
    )
  end
  let(:macro_list_run) do
    Macro::List::Run.new(
      name: 'Macro List Run',
      referential: referential,
      workbench: workbench,
      original_macro_list: macro_list,
      creator: 'Test'
    ).tap do |mlr|
      mlr.build_with_original_macro_list
      mlr.save!
    end
  end

  subject(:macro_context_run) { macro_list_run.macro_context_runs.find { |e| e.name == 'Macro Context Saved Search' } }

  before { referential&.switch }

  context 'with Line search' do
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

        line :line_match1,
             transport_mode: 'bus',
             company: :company_match1,
             network: :network_match1,
             documents: %i[document_line_match1]
        line :line_match2,
             transport_mode: 'bus',
             company: :company_match2,
             network: :network_match2,
             documents: %i[document_line_match2]
        line :line_no_match,
             transport_mode: 'air',
             company: :company_no_match,
             network: :network_no_match,
             documents: %i[document_line_no_match]
        line :line_without_route, transport_mode: 'bus'
        line :line_outside, transport_mode: 'bus'

        stop_area :stop_area_match1, documents: %i[document_stop_area_match1] do
          entrance :entrance_match1
        end
        stop_area :stop_area_match2, documents: %i[document_stop_area_match2] do
          entrance :entrance_match2
        end
        connection_link :connection_link_match, departure: :stop_area_match1, arrival: :stop_area_match2
        stop_area :stop_area_no_match, documents: %i[document_stop_area_no_match] do
          entrance :entrance_no_match
        end
        connection_link :connection_link_no_match, departure: :stop_area_match1, arrival: :stop_area_no_match
        stop_area :stop_area_outside do
          entrance :entrance_outside
        end
        connection_link :connection_link_outside, departure: :stop_area_match1, arrival: :stop_area_outside

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
        shape_provider do
          shape :shape_outside
          point_of_interest :point_of_interest_outside
        end

        referential lines: %i[line_match1 line_match2 line_no_match line_without_route] do
          time_table :time_table_match1
          time_table :time_table_match2
          time_table :time_table_no_match

          route :route_match1, with_stops: false, line: :line_match1 do
            stop_point :stop_point_match1, stop_area: :stop_area_match1
            stop_point :stop_point_match1b, stop_area: :stop_area_match1
            journey_pattern :journey_pattern_match1, shape: :shape_match1 do
              vehicle_journey :vehicle_journey_match1, time_tables: %i[time_table_match1]
            end
          end
          route :route_match2, with_stops: false, line: :line_match2 do
            stop_point :stop_point_match2, stop_area: :stop_area_match2
            stop_point :stop_point_match2b, stop_area: :stop_area_match2
            journey_pattern :journey_pattern_match2, shape: :shape_match2 do
              vehicle_journey :vehicle_journey_match2, time_tables: %i[time_table_match2]
            end
          end
          route :route_no_match, with_stops: false, line: :line_no_match do
            stop_point :stop_point_no_match, stop_area: :stop_area_no_match
            stop_point :stop_point_no_matchb, stop_area: :stop_area_no_match
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

    let(:saved_search_id) do
      workbench.saved_searches.create(
        name: 'bus',
        search_attributes: { transport_mode: %i[bus] },
        search_type: 'Search::Line'
      ).id
    end

    describe '#scope.lines' do
      subject { macro_context_run.scope.lines }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.line(:line_match1),
              context.line(:line_match2),
              context.line(:line_without_route),
              context.line(:line_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.line(:line_match1),
              context.line(:line_match2),
              context.line(:line_without_route)
            ]
          )
        end
      end
    end

    describe '#scope.companies' do
      subject { macro_context_run.scope.companies }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to match_array([context.company(:company_match1), context.company(:company_match2)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.company(:company_match1), context.company(:company_match2)]) }
      end
    end

    describe '#scope.networks' do
      subject { macro_context_run.scope.networks }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to match_array([context.network(:network_match1), context.network(:network_match2)]) }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.network(:network_match1), context.network(:network_match2)]) }
      end
    end

    describe '#scope.stop_areas' do
      subject { macro_context_run.scope.stop_areas }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.stop_area(:stop_area_match1), context.stop_area(:stop_area_match2)]) }
      end
    end

    describe '#scope.entrances' do
      subject { macro_context_run.scope.entrances }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.entrance(:entrance_match1), context.entrance(:entrance_match2)]) }
      end
    end

    describe '#scope.connection_links' do
      subject { macro_context_run.scope.connection_links }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.connection_link(:connection_link_match)]) }
      end
    end

    describe '#scope.shapes' do
      subject { macro_context_run.scope.shapes }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.shape(:shape_match1), context.shape(:shape_match2)]) }
      end
    end

    describe '#scope.point_of_interests' do
      subject { macro_context_run.scope.point_of_interests }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.point_of_interest(:point_of_interest_match1),
              context.point_of_interest(:point_of_interest_match2),
              context.point_of_interest(:point_of_interest_no_match),
              context.point_of_interest(:point_of_interest_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#scope.documents' do
      subject { macro_context_run.scope.documents }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.document(:document_company_match1),
              context.document(:document_company_match2),
              context.document(:document_line_match1),
              context.document(:document_line_match2)
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

    describe '#scope.routes' do
      subject { macro_context_run.scope.routes }

      it { is_expected.to match_array([context.route(:route_match1), context.route(:route_match2)]) }
    end

    describe '#scope.stop_points' do
      subject { macro_context_run.scope.stop_points }

      it do
        is_expected.to match_array(
          [
            context.stop_point(:stop_point_match1),
            context.stop_point(:stop_point_match1b),
            context.stop_point(:stop_point_match2),
            context.stop_point(:stop_point_match2b)
          ]
        )
      end
    end

    describe '#scope.journey_patterns' do
      subject { macro_context_run.scope.journey_patterns }

      it do
        is_expected.to match_array(
          [context.journey_pattern(:journey_pattern_match1), context.journey_pattern(:journey_pattern_match2)]
        )
      end
    end

    describe '#scope.vehicle_journeys' do
      subject { macro_context_run.scope.vehicle_journeys }

      it do
        is_expected.to match_array(
          [context.vehicle_journey(:vehicle_journey_match1), context.vehicle_journey(:vehicle_journey_match2)]
        )
      end
    end

    describe '#scope.time_tables' do
      subject { macro_context_run.scope.time_tables }

      it do
        is_expected.to match_array(
          [
            context.time_table(:time_table_match1),
            context.time_table(:time_table_match2)
          ]
        )
      end
    end

    describe '#scope.service_counts' do
      subject { macro_context_run.scope.service_counts }

      before { service_counts }

      it { is_expected.to match_array([service_count_match1, service_count_match2]) }
    end
  end

  context 'with StopArea search' do
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
        line :line_outside, transport_mode: 'bus'

        stop_area :stop_area_match1, documents: %i[document_stop_area_match1], zip_code: 44_300 do
          entrance :entrance_match1
        end
        stop_area :stop_area_match2, documents: %i[document_stop_area_match2], zip_code: 44_300 do
          entrance :entrance_match2
        end
        connection_link :connection_link_match, departure: :stop_area_match1, arrival: :stop_area_match2
        stop_area :stop_area_no_match, documents: %i[document_stop_area_no_match], zip_code: 0o0000 do
          entrance :entrance_no_match
        end
        connection_link :connection_link_no_match, departure: :stop_area_match1, arrival: :stop_area_no_match
        stop_area :stop_area_outside, zip_code: 44_300 do
          entrance :entrance_outside
        end
        connection_link :connection_link_outside, departure: :stop_area_match1, arrival: :stop_area_outside

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
        shape_provider do
          shape :shape_outside
          point_of_interest :point_of_interest_outside
        end

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

    let(:saved_search_id) do
      workbench.saved_searches.create(
        name: 'zip code 44300',
        search_attributes: { zip_code: '44300' },
        search_type: 'Search::StopArea'
      ).id
    end

    describe '#scope.lines' do
      subject { macro_context_run.scope.lines }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.line(:line_match1), context.line(:line_match2)]) }
      end
    end

    describe '#scope.companies' do
      subject { macro_context_run.scope.companies }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.company(:company_match1), context.company(:company_match2)]) }
      end
    end

    describe '#scope.networks' do
      subject { macro_context_run.scope.networks }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.network(:network_match1), context.network(:network_match2)]) }
      end
    end

    describe '#scope.stop_areas' do
      subject { macro_context_run.scope.stop_areas }

      context 'in workbench' do
        let(:referential) { nil }

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

    describe '#scope.entrances' do
      subject { macro_context_run.scope.entrances }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.entrance(:entrance_match1),
              context.entrance(:entrance_match2),
              context.entrance(:entrance_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to match_array([context.entrance(:entrance_match1), context.entrance(:entrance_match2)]) }
      end
    end

    describe '#scope.connection_links' do
      subject { macro_context_run.scope.connection_links }

      context 'in workbench' do
        let(:referential) { nil }

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

    describe '#scope.shapes' do
      subject { macro_context_run.scope.shapes }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.shape(:shape_match1), context.shape(:shape_match2)]) }
      end
    end

    describe '#scope.point_of_interests' do
      subject { macro_context_run.scope.point_of_interests }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.point_of_interest(:point_of_interest_match1),
              context.point_of_interest(:point_of_interest_match2),
              context.point_of_interest(:point_of_interest_no_match),
              context.point_of_interest(:point_of_interest_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#scope.documents' do
      subject { macro_context_run.scope.documents }

      context 'in workbench' do
        let(:referential) { nil }

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

    describe '#scope.routes' do
      subject { macro_context_run.scope.routes }

      it { is_expected.to match_array([context.route(:route_match1), context.route(:route_match2)]) }
    end

    describe '#scope.stop_points' do
      subject { macro_context_run.scope.stop_points }

      it do
        is_expected.to match_array([context.stop_point(:stop_point_match1), context.stop_point(:stop_point_match2)])
      end
    end

    describe '#scope.journey_patterns' do
      subject { macro_context_run.scope.journey_patterns }

      it do
        is_expected.to match_array(
          [context.journey_pattern(:journey_pattern_match1), context.journey_pattern(:journey_pattern_match2)]
        )
      end
    end

    describe '#scope.vehicle_journeys' do
      subject { macro_context_run.scope.vehicle_journeys }

      it do
        is_expected.to match_array(
          [context.vehicle_journey(:vehicle_journey_match1), context.vehicle_journey(:vehicle_journey_match2)]
        )
      end
    end

    describe '#scope.time_tables' do
      subject { macro_context_run.scope.time_tables }

      it do
        is_expected.to match_array(
          [
            context.time_table(:time_table_match1),
            context.time_table(:time_table_match2)
          ]
        )
      end
    end

    describe '#scope.service_counts' do
      subject { macro_context_run.scope.service_counts }

      before { service_counts }

      it { is_expected.to match_array([service_count_match1, service_count_match2]) }
    end
  end

  context 'with search on any other model' do
    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        document :document_company_match1
        document :document_company_match2
        document :document_company_without_line
        document :document_line_match1
        document :document_line_match2
        document :document_stop_area_match1
        document :document_stop_area_match2
        document :document_stop_area_outside

        company :company_match1, documents: %i[document_company_match1]
        company :company_match2, documents: %i[document_company_match2]
        company :company_without_line, documents: %i[document_company_without_line]

        network :network_match1
        network :network_match2
        network :network_without_line

        line :line_match1, company: :company_match1, network: :network_match1, documents: %i[document_line_match1]
        line :line_match2, company: :company_match2, network: :network_match2, documents: %i[document_line_match2]
        line :line_without_route
        line :line_outside

        stop_area :stop_area_match1, documents: %i[document_stop_area_match1] do
          entrance :entrance_match1
        end
        stop_area :stop_area_match2, documents: %i[document_stop_area_match2] do
          entrance :entrance_match2
        end
        connection_link :connection_link_match, departure: :stop_area_match1, arrival: :stop_area_match2
        stop_area :stop_area_outside, documents: %i[document_stop_area_outside] do
          entrance :entrance_outside
        end
        connection_link :connection_link_outside, departure: :stop_area_match1, arrival: :stop_area_outside

        shape_provider do
          shape :shape_match1
          point_of_interest :point_of_interest_match1
        end
        shape_provider do
          shape :shape_match2
          point_of_interest :point_of_interest_match2
        end
        shape_provider do
          shape :shape_outside
          point_of_interest :point_of_interest_outside
        end

        referential lines: %i[line_match1 line_match2 line_without_route] do
          time_table :time_table_match1
          time_table :time_table_match2

          route :route_match1, with_stops: false, line: :line_match1 do
            stop_point :stop_point_match1, stop_area: :stop_area_match1
            stop_point :stop_point_match1b, stop_area: :stop_area_match1
            journey_pattern :journey_pattern_match1, shape: :shape_match1 do
              vehicle_journey :vehicle_journey_match1, time_tables: %i[time_table_match1]
            end
          end
          route :route_match2, with_stops: false, line: :line_match2 do
            stop_point :stop_point_match2, stop_area: :stop_area_match2
            stop_point :stop_point_match2b, stop_area: :stop_area_match2
            journey_pattern :journey_pattern_match2, shape: :shape_match2 do
              vehicle_journey :vehicle_journey_match2, time_tables: %i[time_table_match2]
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
    let(:service_counts) { [service_count_match1, service_count_match2] }

    let(:saved_search_id) do
      workbench.saved_searches.create(
        name: 'Plop',
        search_attributes: { name: 'Plop' },
        search_type: 'Search::Import'
      ).id
    end

    describe '#scope.lines' do
      subject { macro_context_run.scope.lines }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it do
          is_expected.to match_array(
            [
              context.line(:line_match1),
              context.line(:line_match2)
            ]
          )
        end
      end
    end

    describe '#scope.companies' do
      subject { macro_context_run.scope.companies }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.company(:company_match1), context.company(:company_match2)]) }
      end
    end

    describe '#scope.networks' do
      subject { macro_context_run.scope.networks }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.network(:network_match1), context.network(:network_match2)]) }
      end
    end

    describe '#scope.stop_areas' do
      subject { macro_context_run.scope.stop_areas }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.stop_area(:stop_area_match1), context.stop_area(:stop_area_match2)]) }
      end
    end

    describe '#scope.entrances' do
      subject { macro_context_run.scope.entrances }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.entrance(:entrance_match1), context.entrance(:entrance_match2)]) }
      end
    end

    describe '#scope.connection_links' do
      subject { macro_context_run.scope.connection_links }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.connection_link(:connection_link_match)]) }
      end
    end

    describe '#scope.shapes' do
      subject { macro_context_run.scope.shapes }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
      end

      context 'in referential' do
        it { is_expected.to match_array([context.shape(:shape_match1), context.shape(:shape_match2)]) }
      end
    end

    describe '#scope.point_of_interests' do
      subject { macro_context_run.scope.point_of_interests }

      context 'in workbench' do
        let(:referential) { nil }

        it do
          is_expected.to match_array(
            [
              context.point_of_interest(:point_of_interest_match1),
              context.point_of_interest(:point_of_interest_match2),
              context.point_of_interest(:point_of_interest_outside)
            ]
          )
        end
      end

      context 'in referential' do
        it { is_expected.to be_empty }
      end
    end

    describe '#scope.documents' do
      subject { macro_context_run.scope.documents }

      context 'in workbench' do
        let(:referential) { nil }

        it { is_expected.to be_empty }
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

    describe '#scope.routes' do
      subject { macro_context_run.scope.routes }

      it { is_expected.to match_array([context.route(:route_match1), context.route(:route_match2)]) }
    end

    describe '#scope.stop_points' do
      subject { macro_context_run.scope.stop_points }

      it do
        is_expected.to match_array(
          [
            context.stop_point(:stop_point_match1),
            context.stop_point(:stop_point_match1b),
            context.stop_point(:stop_point_match2),
            context.stop_point(:stop_point_match2b)
          ]
        )
      end
    end

    describe '#scope.journey_patterns' do
      subject { macro_context_run.scope.journey_patterns }

      it do
        is_expected.to match_array(
          [context.journey_pattern(:journey_pattern_match1), context.journey_pattern(:journey_pattern_match2)]
        )
      end
    end

    describe '#scope.vehicle_journeys' do
      subject { macro_context_run.scope.vehicle_journeys }

      it do
        is_expected.to match_array(
          [context.vehicle_journey(:vehicle_journey_match1), context.vehicle_journey(:vehicle_journey_match2)]
        )
      end
    end

    describe '#scope.time_tables' do
      subject { macro_context_run.scope.time_tables }

      it do
        is_expected.to match_array(
          [
            context.time_table(:time_table_match1),
            context.time_table(:time_table_match2)
          ]
        )
      end
    end

    describe '#scope.service_counts' do
      subject { macro_context_run.scope.service_counts }

      before { service_counts }

      it { is_expected.to match_array([service_count_match1, service_count_match2]) }
    end
  end
end
