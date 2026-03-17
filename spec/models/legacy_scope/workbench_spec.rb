# frozen_string_literal: true

RSpec.describe LegacyScope::Workbench do
  subject(:scope) { described_class.new(workbench) }

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

  describe '#booking_arrangements' do
    subject { scope.booking_arrangements }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            booking_arrangement :booking_arrangement
          end
        end

        workgroup do
          workbench :other_workbench do
            booking_arrangement
          end
        end
      end
    end

    it { is_expected.to match_array([context.booking_arrangement(:booking_arrangement)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.booking_arrangement(:booking_arrangement)]) }
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

  describe '#accessibility_assessments' do
    subject { scope.accessibility_assessments }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench

          workbench :workbench do
            accessibility_assessment :accessibility_assessment
          end
        end

        workgroup do
          workbench :other_workbench do
            accessibility_assessment
          end
        end
      end
    end

    it { is_expected.to match_array([context.accessibility_assessment(:accessibility_assessment)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.accessibility_assessment(:accessibility_assessment)]) }
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

  describe '#contracts' do
    subject { scope.contracts }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :same_workgroup_workbench do
            company :company_other_workbench
            line :line_other_workbench
            contract :contract_other_workbench, company: :company_other_workbench, lines: %i[line_other_workbench]
          end

          workbench :workbench do
            company :company
            line :line
            contract :contract, company: :company, lines: %i[line]
          end
        end
      end
    end

    it { is_expected.to match_array([context.contract(:contract)]) }

    context 'in workbench in the same workgroup' do
      let(:workbench) { context.workbench(:same_workgroup_workbench) }

      it { is_expected.to match_array([context.contract(:contract_other_workbench)]) }
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
