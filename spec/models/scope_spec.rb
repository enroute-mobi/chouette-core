# frozen_string_literal: true

RSpec.describe Scope::Workbench do
  subject(:scope) { Scope::Workbench.new(workbench) }

  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) rescue nil } # rubocop:disable Style/RescueModifier

  before { referential&.switch }

  describe '#lines' do
    subject { scope.lines }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line
          end
        end

        workgroup do
          workbench :other_workbench do
            line
          end
        end
      end
    end

    it { is_expected.to match_array([context.line(:line)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line(:line)]) }
    end
  end

  describe '#line_groups' do
    subject { scope.line_groups }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line
            line_group :line_group, lines: %i[line]
          end
        end

        workgroup do
          workbench :other_workbench do
            line :other_line
            line_group lines: %i[other_line]
          end
        end
      end
    end

    it { is_expected.to match_array([context.line_group(:line_group)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line_group(:line_group)]) }
    end
  end

  describe '#line_notices' do
    subject { scope.line_notices }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line_notice :line_notice
          end
        end

        workgroup do
          workbench :other_workbench do
            line_notice
          end
        end
      end
    end

    it { is_expected.to match_array([context.line_notice(:line_notice)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line_notice(:line_notice)]) }
    end
  end

  describe '#companies' do
    subject { scope.companies }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            company :company
          end
        end

        workgroup do
          workbench :other_workbench do
            company
          end
        end
      end
    end

    it { is_expected.to match_array([context.company(:company)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.company(:company)]) }
    end
  end

  describe '#networks' do
    subject { scope.networks }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            network :network
          end
        end

        workgroup do
          workbench :other_workbench do
            network
          end
        end
      end
    end

    it { is_expected.to match_array([context.network(:network)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.network(:network)]) }
    end
  end

  describe '#stop_areas' do
    subject { scope.stop_areas }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
          end
        end

        workgroup do
          workbench :other_workbench do
            stop_area
          end
        end
      end
    end

    it { is_expected.to match_array([context.stop_area(:stop_area)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_area(:stop_area)]) }
    end
  end

  describe '#stop_area_groups' do
    subject { scope.stop_area_groups }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            stop_area_group :stop_area_group, stop_areas: %i[stop_area]
          end
        end

        workgroup do
          workbench :other_workbench do
            stop_area :other_stop_area
            stop_area_group stop_areas: %i[other_stop_area]
          end
        end
      end
    end

    it { is_expected.to match_array([context.stop_area_group(:stop_area_group)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#entrances' do
    subject { scope.entrances }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            entrance :entrance
          end
        end

        workgroup do
          workbench :other_workbench do
            entrance
          end
        end
      end
    end

    it { is_expected.to match_array([context.entrance(:entrance)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#connection_links' do
    subject { scope.connection_links }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area1
            stop_area :stop_area2
            connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2
          end
        end

        workgroup do
          workbench :other_workbench do
            stop_area :other_stop_area1
            stop_area :other_stop_area2
            connection_link departure: :other_stop_area1, arrival: :other_stop_area2
          end
        end
      end
    end

    it { is_expected.to match_array([context.connection_link(:connection_link)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#shapes' do
    subject { scope.shapes }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            shape :shape
          end
        end

        workgroup do
          workbench :other_workbench do
            shape
          end
        end
      end
    end

    it { is_expected.to match_array([context.shape(:shape)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#point_of_interests' do
    subject { scope.point_of_interests }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            point_of_interest :point_of_interest
          end
        end

        workgroup do
          workbench :other_workbench do
            point_of_interest
          end
        end
      end
    end

    it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }
    end
  end

  describe '#service_facility_sets' do
    subject { scope.service_facility_sets }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            service_facility_set :service_facility_set
          end
        end

        workgroup do
          workbench :other_workbench do
            service_facility_set
          end
        end
      end
    end

    it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }
    end
  end

  describe '#fare_zones' do
    subject { scope.fare_zones }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            fare_zone :fare_zone
          end
        end

        workgroup do
          workbench :other_workbench do
            fare_zone
          end
        end
      end
    end

    it { is_expected.to match_array([context.fare_zone(:fare_zone)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#line_routing_constraint_zones' do
    subject { scope.line_routing_constraint_zones }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            line :line
            line_routing_constraint_zone :line_routing_constraint_zone, lines: %i[line], stop_areas: %i[stop_area]
          end
        end

        workgroup do
          workbench :other_workbench do
            stop_area :other_stop_area
            line :other_line
            line_routing_constraint_zone lines: %i[other_line], stop_areas: %i[other_stop_area]
          end
        end
      end
    end

    it { is_expected.to match_array([context.line_routing_constraint_zone(:line_routing_constraint_zone)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line_routing_constraint_zone(:line_routing_constraint_zone)]) }
    end
  end

  describe '#documents' do
    subject { scope.documents }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench do
            document :document_other_workbench
          end

          workbench :workbench do
            document :document
          end
        end
      end
    end

    it { is_expected.to match_array([context.document(:document)]) }

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

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential do
                time_table dates_included: Time.zone.today,
                           periods: [Time.zone.yesterday..Time.zone.tomorrow]

                route do
                  journey_pattern do
                    vehicle_journey
                  end
                end
              end
            end
          end
        end
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#service_counts' do
    subject { scope.service_counts }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :workbench do
            line :line

            referential lines: %i[line] do
              route :route, line: :line do
                journey_pattern :journey_pattern
              end
            end
          end
        end
      end
    end
    let!(:service_count) do
      ServiceCount.create!(
        line: context.line(:line),
        route: context.route(:route),
        journey_pattern: context.journey_pattern(:journey_pattern),
        date: Time.zone.today
      )
    end

    it { is_expected.to be_empty }
  end
end

RSpec.describe Scope::Referential do
  subject(:scope) { Scope::Referential.new(workbench, referential) }

  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  before { referential.switch }

  describe '#lines' do
    subject { scope.lines }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line
            line :line_outside

            referential :referential, lines: %i[line]

            referential :same_workbench_referential

            referential lines: %i[line_outside]
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.line(:line)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to match_array([be_a(Chouette::Line)]) }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line(:line)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([context.line(:line)]) }
    end
  end

  describe '#line_groups' do
    subject { scope.line_groups }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line
            line :line_outside

            line_group :line_group, lines: %i[line]
            line_group :line_group_outside, lines: %i[line_outside]

            referential :referential, lines: %i[line]

            referential :same_workbench_referential

            referential lines: %i[line_outside]
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.line_group(:line_group)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line_group(:line_group)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#line_notices' do
    subject { scope.line_notices }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line
            line :line_outside

            line_notice :line_notice, lines: %i[line]
            line_notice :line_notice_outside, lines: %i[line_outside]

            referential :referential, lines: %i[line]

            referential :same_workbench_referential

            referential lines: %i[line_outside]
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.line_notice(:line_notice)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.line_notice(:line_notice)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#companies' do
    subject { scope.companies }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            company :company
            company :company_outside

            line :line, company: :company
            line :line_outside, company: :company_outside

            referential :referential, lines: %i[line]

            referential :same_workbench_referential

            referential lines: %i[line_outside]
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            network :network
            network :network_outside

            line :line, network: :network
            line :line_outside, network: :network_outside

            referential :referential, lines: %i[line]

            referential :same_workbench_referential

            referential lines: %i[line_outside]
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            stop_area :stop_area_outside

            referential :referential do
              route with_stops: false do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.stop_area(:stop_area)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_area(:stop_area)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#stop_area_groups' do
    subject { scope.stop_area_groups }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            stop_area :stop_area_outside

            stop_area_group :stop_area_group, stop_areas: %i[stop_area]
            stop_area_group :stop_area_group_outside, stop_areas: %i[stop_area_outside]

            referential :referential do
              route with_stops: false do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.stop_area_group(:stop_area_group)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.stop_area_group(:stop_area_group)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#entrances' do
    subject { scope.entrances }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area do
              entrance :entrance
            end
            stop_area :stop_area_outside do
              entrance :entrance_outside
            end

            referential :referential do
              route with_stops: false do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area1
            stop_area :stop_area2
            connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2
            stop_area :stop_area_outside
            connection_link :connection_link_outside, departure: :stop_area1, arrival: :stop_area_outside

            referential :referential do
              route with_stops: false do
                stop_point :stop_point1, stop_area: :stop_area1
                stop_point :stop_point2, stop_area: :stop_area2
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point stop_area: :stop_area1
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            shape :shape
            shape :shape_outside

            referential :referential do
              journey_pattern shape: :shape
            end

            referential :same_workbench_referential

            referential do
              journey_pattern shape: :shape_outside
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :workbench do
            point_of_interest :point_of_interest

            referential :referential
          end
        end
      end
    end

    it { is_expected.to be_empty }
  end

  describe '#service_facility_sets' do
    subject { scope.service_facility_sets }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            service_facility_set :service_facility_set
            service_facility_set :service_facility_set_outside

            referential :referential do
              vehicle_journey service_facility_sets: %i[service_facility_set]
            end

            referential :same_workbench_referential

            referential do
              vehicle_journey service_facility_sets: %i[service_facility_set_outside]
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#fare_zones' do
    subject { scope.fare_zones }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            stop_area :stop_area_outside

            fare_zone :fare_zone, stop_areas: %i[stop_area]
            fare_zone :fare_zone_outside, stop_areas: %i[stop_area_outside]

            referential :referential do
              route with_stops: false do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([context.fare_zone(:fare_zone)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.fare_zone(:fare_zone)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#line_routing_constraint_zones' do
    subject { scope.line_routing_constraint_zones }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do # rubocop:disable Metrics/BlockLength
          workbench :same_workgroup_workbench

          workbench :workbench do
            stop_area :stop_area
            stop_area :stop_area_outside

            line :line
            line :line_outside

            line_routing_constraint_zone :line_routing_constraint_zone, lines: %i[line], stop_areas: %i[stop_area]
            line_routing_constraint_zone :line_routing_constraint_zone_line_outside,
                                         lines: %i[line_outside], stop_areas: %i[stop_area]
            line_routing_constraint_zone :line_routing_constraint_zone_stop_area_outside,
                                         lines: %i[line], stop_areas: %i[stop_area_outside]
            line_routing_constraint_zone :line_routing_constraint_zone_both_outside,
                                         lines: %i[line_outside], stop_areas: %i[stop_area_outside]

            referential :referential, lines: %i[line] do
              route with_stops: false, line: :line do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential lines: %i[line_outside] do
              route with_stops: false, line: :line_outside do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it do
      is_expected.to match_array(
        [
          context.line_routing_constraint_zone(:line_routing_constraint_zone),
          context.line_routing_constraint_zone(:line_routing_constraint_zone_line_outside),
          context.line_routing_constraint_zone(:line_routing_constraint_zone_stop_area_outside)
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
            context.line_routing_constraint_zone(:line_routing_constraint_zone),
            context.line_routing_constraint_zone(:line_routing_constraint_zone_line_outside),
            context.line_routing_constraint_zone(:line_routing_constraint_zone_stop_area_outside)
          ]
        )
      end
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to be_empty }
    end
  end

  describe '#documents' do
    subject { scope.documents }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do # rubocop:disable Metrics/BlockLength
          workbench :same_workgroup_workbench do
            document :document_other_workbench
          end

          workbench :workbench do
            document :document_company
            document :document_line
            document :document_stop_area
            document :document_outside
            document :document_unassociated

            company :company, documents: %i[document_company]
            company :company_outside, documents: %i[document_outside]

            line :line, company: :company, network: :network, documents: %i[document_line document_other_workbench]
            line :line_outside, company: :company_outside, network: :network_outside, documents: %i[document_outside]

            stop_area :stop_area, documents: %i[document_stop_area]
            stop_area :stop_area_outside, documents: %i[document_outside]

            referential :referential, lines: %i[line] do
              route with_stops: false, line: :line do
                stop_point stop_area: :stop_area
                stop_point stop_area: :stop_area
              end
            end

            referential :same_workbench_referential

            referential lines: %i[line_outside] do
              route with_stops: false, line: :line_outside do
                stop_point stop_area: :stop_area_outside
                stop_point stop_area: :stop_area_outside
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              route :route
            end

            referential :same_workbench_referential

            referential do
              route
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              route with_stops: false do
                stop_point :stop_point1
                stop_point :stop_point2
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point
                stop_point
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              journey_pattern :journey_pattern
            end

            referential :same_workbench_referential

            referential do
              journey_pattern
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              route with_stops: false do
                stop_point :stop_point1
                stop_point :stop_point2
                journey_pattern
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point
                stop_point
                journey_pattern
              end
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              vehicle_journey :vehicle_journey
            end

            referential :same_workbench_referential

            referential do
              vehicle_journey
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              route with_stops: false do
                stop_point :stop_point1
                stop_point :stop_point2
                journey_pattern do
                  vehicle_journey
                end
              end
            end

            referential :same_workbench_referential

            referential do
              route with_stops: false do
                stop_point
                stop_point
                journey_pattern do
                  vehicle_journey
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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              time_table :time_table
            end

            referential :same_workbench_referential

            referential do
              time_table
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              time_table periods: [
                2.days.ago.to_date..1.day.ago.to_date,
                1.day.from_now.to_date..2.days.from_now.to_date
              ]
            end

            referential :same_workbench_referential

            referential do
              time_table periods: [
                2.days.ago.to_date..1.day.ago.to_date,
                1.day.from_now.to_date..2.days.from_now.to_date
              ]
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

    it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod), be_a(Chouette::TimeTablePeriod)]) }

    context 'in referential in the same workbench' do
      let(:referential) { context.referential(:same_workbench_referential) }

      it { is_expected.to be_empty }
    end

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod), be_a(Chouette::TimeTablePeriod)]) }
    end

    context 'in workbench of another workgroup' do
      let(:workbench) { context.workbench(:other_workbench) }

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod), be_a(Chouette::TimeTablePeriod)]) }
    end
  end

  describe '#time_table_dates' do
    subject { scope.time_table_dates }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            referential :referential do
              time_table dates_included: Time.zone.today
            end

            referential :same_workbench_referential

            referential do
              time_table dates_included: Time.zone.today
            end
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end

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

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            line :line

            referential :referential, lines: %i[line] do
              route :route, line: :line do
                journey_pattern :journey_pattern
              end
            end

            referential :same_workbench_referential
          end
        end

        workgroup do
          workbench :other_workbench
        end
      end
    end
    let!(:service_count) do
      ServiceCount.create!(
        line: context.line(:line),
        route: context.route(:route),
        journey_pattern: context.journey_pattern(:journey_pattern),
        date: Time.zone.today
      )
    end

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
  let(:referential) { context.referential(:referential) rescue nil } # rubocop:disable Style/RescueModifier

  before { referential&.switch }

  context 'of Scope::Workbench' do
    let(:parent_scope) { Scope::Workbench.new(context.workbench(:workbench)) }

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.line(:line)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#line_groups' do
      subject { scope.line_groups }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line
              line_group :line_group, lines: %i[line]
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.line_group(:line_group)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#line_notices' do
      subject { scope.line_notices }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line_notice :line_notice
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.line_notice(:line_notice)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#companies' do
      subject { scope.companies }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              company :company
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.company(:company)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#networks' do
      subject { scope.networks }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              network :network
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.network(:network)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area :stop_area
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.stop_area(:stop_area)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#stop_area_groups' do
      subject { scope.stop_area_groups }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area :stop_area
              stop_area_group :stop_area_group, stop_areas: %i[stop_area]
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.stop_area_group(:stop_area_group)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              entrance :entrance
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.entrance(:entrance)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area :stop_area1
              stop_area :stop_area2
              connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.connection_link(:connection_link)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#shapes' do
      subject { scope.shapes }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              shape :shape
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.shape(:shape)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              point_of_interest :point_of_interest
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.point_of_interest(:point_of_interest)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#service_facility_sets' do
      subject { scope.service_facility_sets }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              service_facility_set :service_facility_set
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#fare_zones' do
      subject { scope.fare_zones }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              fare_zone :fare_zone
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.fare_zone(:fare_zone)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#line_routing_constraint_zones' do
      subject { scope.line_routing_constraint_zones }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              stop_area :stop_area
              line :line
              line_routing_constraint_zone :line_routing_constraint_zone, lines: %i[line], stop_areas: %i[stop_area]
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.line_routing_constraint_zone(:line_routing_constraint_zone)]) }

      context 'in workbench in the same workgroup' do
        let(:workbench) { context.workbench(:same_workgroup_workbench) }

        it { is_expected.to be_empty }
      end
    end

    describe '#documents' do
      subject { scope.documents }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              document :document
            end

            workbench :same_workgroup_workbench
          end
        end
      end

      it { is_expected.to match_array([context.document(:document)]) }

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

        let(:context) do
          Chouette.create do
            workgroup do
              workbench :same_workgroup_workbench

              workbench :workbench do
                referential :referential do
                  time_table dates_included: Time.zone.today
                end

                referential :same_workbench_referential

                referential do
                  time_table dates_included: Time.zone.today
                end
              end
            end

            workgroup do
              workbench :other_workbench
            end
          end
        end

        it { is_expected.to be_empty }
      end
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line

              referential lines: %i[line] do
                route :route, line: :line do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end
      end
      let!(:service_count) do
        ServiceCount.create!(
          line: context.line(:line),
          route: context.route(:route),
          journey_pattern: context.journey_pattern(:journey_pattern),
          date: Time.zone.today
        )
      end

      it { is_expected.to be_empty }
    end
  end

  context 'of Scope::Referential' do
    let(:parent_scope) { Scope::Referential.new(context.workbench(:workbench), context.referential(:referential)) }

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              line :line_outside
            end

            workbench :workbench do
              line :line

              referential :referential, lines: %i[line line_outside]
            end
          end
        end
      end

      it { is_expected.to match_array([context.line(:line)]) }
    end

    describe '#line_groups' do
      subject { scope.line_groups }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              line :line_outside
              line_group lines: %i[line_outside]
            end

            workbench :workbench do
              line :line
              line_group :line_group, lines: %i[line]

              referential :referential, lines: %i[line line_outside]
            end
          end
        end
      end

      it { is_expected.to match_array([context.line_group(:line_group)]) }
    end

    describe '#line_notices' do
      subject { scope.line_notices }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              line :line_outside
              line_notice lines: %i[line_outside]
            end

            workbench :workbench do
              line :line
              line_notice :line_notice, lines: %i[line]

              referential :referential, lines: %i[line line_outside]
            end
          end
        end
      end

      it { is_expected.to match_array([context.line_notice(:line_notice)]) }
    end

    describe '#companies' do
      subject { scope.companies }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              company :company_outside
              line :line_outside, company: :company_outside
            end

            workbench :workbench do
              company :company
              line :line, company: :company

              referential :referential, lines: %i[line line_outside]
            end
          end
        end
      end

      it { is_expected.to match_array([context.company(:company)]) }
    end

    describe '#networks' do
      subject { scope.networks }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              network :network_outside
              line :line_outside, network: :network_outside
            end

            workbench :workbench do
              network :network
              line :line, network: :network

              referential :referential, lines: %i[line line_outside]
            end
          end
        end
      end

      it { is_expected.to match_array([context.network(:network)]) }
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside
            end

            workbench :workbench do
              stop_area :stop_area

              referential :referential do
                route :route, with_stops: false do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area_outside
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.stop_area(:stop_area)]) }
    end

    describe '#stop_area_groups' do
      subject { scope.stop_area_groups }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside
              stop_area_group stop_areas: %i[stop_area_outside]
            end

            workbench :workbench do
              stop_area :stop_area
              stop_area_group :stop_area_group, stop_areas: %i[stop_area]

              referential :referential do
                route :route, with_stops: false do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area_outside
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.stop_area_group(:stop_area_group)]) }
    end

    describe '#entrances' do
      subject { scope.entrances }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside do
                entrance
              end
            end

            workbench :workbench do
              stop_area :stop_area do
                entrance :entrance
              end

              referential :referential do
                route :route, with_stops: false do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area_outside
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.entrance(:entrance)]) }
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside1
              stop_area :stop_area_outside2
              connection_link departure: :stop_area_outside1, arrival: :stop_area_outside2
            end

            workbench :workbench do
              stop_area :stop_area1
              stop_area :stop_area2
              connection_link :connection_link, departure: :stop_area1, arrival: :stop_area2

              referential :referential do
                route :route, with_stops: false do
                  stop_point stop_area: :stop_area1
                  stop_point stop_area: :stop_area2
                  stop_point stop_area: :stop_area_outside1
                  stop_point stop_area: :stop_area_outside2
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.connection_link(:connection_link)]) }
    end

    describe '#shapes' do
      subject { scope.shapes }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              shape :shape_outside
            end

            workbench :workbench do
              shape :shape

              referential :referential do
                journey_pattern shape: :shape
                journey_pattern shape: :shape_outside
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.shape(:shape)]) }
    end

    describe '#point_of_interests' do
      subject { scope.point_of_interests }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              point_of_interest :point_of_interest

              referential :referential
            end
          end
        end
      end

      it { is_expected.to be_empty }
    end

    describe '#service_facility_sets' do
      subject { scope.service_facility_sets }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              service_facility_set :service_facility_set_outside
            end

            workbench :workbench do
              service_facility_set :service_facility_set

              referential :referential do
                vehicle_journey service_facility_sets: %i[service_facility_set]
                vehicle_journey service_facility_sets: %i[service_facility_set_outside]
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.service_facility_set(:service_facility_set)]) }
    end

    describe '#fare_zones' do
      subject { scope.fare_zones }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside
              fare_zone :fare_zone_outside, stop_areas: %i[stop_area_outside]
            end

            workbench :workbench do
              stop_area :stop_area
              fare_zone :fare_zone, stop_areas: %i[stop_area]

              referential :referential do
                route :route, with_stops: false do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area_outside
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.fare_zone(:fare_zone)]) }
    end

    describe '#line_routing_constraint_zones' do
      subject { scope.line_routing_constraint_zones }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              stop_area :stop_area_outside
              line :line_outside
            end

            workbench :workbench do
              stop_area :stop_area
              line :line

              line_routing_constraint_zone :line_routing_constraint_zone, lines: %i[line], stop_areas: %i[stop_area]
              line_routing_constraint_zone :line_routing_constraint_zone_line_outside,
                                           lines: %i[line_outside], stop_areas: %i[stop_area]
              line_routing_constraint_zone :line_routing_constraint_zone_stop_area_outside,
                                           lines: %i[line], stop_areas: %i[stop_area_outside]
              line_routing_constraint_zone :line_routing_constraint_zone_both_outside,
                                           lines: %i[line_outside], stop_areas: %i[stop_area_outside]

              referential :referential, lines: %i[line] do
                route with_stops: false, line: :line do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area
                end
              end
            end
          end
        end
      end
      let!(:line_routing_constraint_zone_outside) do
        context.workbench(:same_workgroup_workbench).line_providers.last.line_routing_constraint_zones.create!(
          name: 'Line routing constraint zone outside',
          lines: [context.line(:line)],
          stop_areas: [context.stop_area(:stop_area)]
        )
      end

      it do
        is_expected.to match_array(
          [
            context.line_routing_constraint_zone(:line_routing_constraint_zone),
            context.line_routing_constraint_zone(:line_routing_constraint_zone_line_outside),
            context.line_routing_constraint_zone(:line_routing_constraint_zone_stop_area_outside)
          ]
        )
      end
    end

    describe '#documents' do
      subject { scope.documents }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :same_workgroup_workbench do
              document :document_outside

              company :company_outside, documents: %i[document_outside]
              line :line_outside, company: :company_outside, documents: %i[document_outside]
              stop_area :stop_area_outside, documents: %i[document_outside]
            end

            workbench :workbench do
              document :document_company
              document :document_line
              document :document_stop_area

              company :company, documents: %i[document_company]
              line :line, company: :company, documents: %i[document_line]
              stop_area :stop_area, documents: %i[document_stop_area]

              referential :referential, lines: %i[line line_outside] do
                route :route, with_stops: false, line: :line do
                  stop_point stop_area: :stop_area
                  stop_point stop_area: :stop_area_outside
                end
              end
            end
          end
        end
      end

      it do
        is_expected.to match_array(
          [
            context.document(:document_company),
            context.document(:document_line),
            context.document(:document_stop_area)
          ]
        )
      end
    end

    describe '#routes' do
      subject { scope.routes }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                route :route
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.route(:route)]) }
    end

    describe '#stop_points' do
      subject { scope.stop_points }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                route with_stops: false do
                  stop_point :stop_point1
                  stop_point :stop_point2
                end
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.stop_point(:stop_point1), context.stop_point(:stop_point2)]) }
    end

    describe '#journey_patterns' do
      subject { scope.journey_patterns }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                journey_pattern :journey_pattern
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.journey_pattern(:journey_pattern)]) }
    end

    describe '#journey_pattern_stop_points' do
      subject { scope.journey_pattern_stop_points }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                route with_stops: false do
                  stop_point :stop_point1
                  stop_point :stop_point2
                  journey_pattern
                end
              end
            end
          end
        end
      end

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end

    describe '#vehicle_journeys' do
      subject { scope.vehicle_journeys }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                vehicle_journey :vehicle_journey
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.vehicle_journey(:vehicle_journey)]) }
    end

    describe '#vehicle_journey_at_stops' do
      subject { scope.vehicle_journey_at_stops }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                route with_stops: false do
                  stop_point :stop_point1
                  stop_point :stop_point2
                  journey_pattern do
                    vehicle_journey
                  end
                end
              end
            end
          end
        end
      end

      it do
        is_expected.to match_array(
          [
            have_attributes(stop_point: context.stop_point(:stop_point1)),
            have_attributes(stop_point: context.stop_point(:stop_point2))
          ]
        )
      end
    end

    describe '#time_tables' do
      subject { scope.time_tables }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                time_table :time_table
              end
            end
          end
        end
      end

      it { is_expected.to match_array([context.time_table(:time_table)]) }
    end

    describe '#time_table_periods' do
      subject { scope.time_table_periods }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                time_table periods: [
                  2.days.ago.to_date..1.day.ago.to_date,
                  1.day.from_now.to_date..2.days.from_now.to_date
                ]
              end
            end
          end
        end
      end

      it { is_expected.to match_array([be_a(Chouette::TimeTablePeriod), be_a(Chouette::TimeTablePeriod)]) }
    end

    describe '#time_table_dates' do
      subject { scope.time_table_dates }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential do
                time_table dates_included: Time.zone.today
              end
            end
          end
        end
      end

      it { is_expected.to match_array([be_a(Chouette::TimeTableDate)]) }
    end

    describe '#service_counts' do
      subject { scope.service_counts }

      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              line :line

              referential :referential, lines: %i[line] do
                route :route, line: :line do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end
      end
      let!(:service_count) do
        ServiceCount.create!(
          line: context.line(:line),
          route: context.route(:route),
          journey_pattern: context.journey_pattern(:journey_pattern),
          date: Time.zone.today
        )
      end

      it { is_expected.to match_array([service_count]) }
    end
  end
end
