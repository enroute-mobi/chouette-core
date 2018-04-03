require "rails_helper"

RSpec.describe Merge do

  let(:stop_area_referential) { create :stop_area_referential }
  let(:line_referential)      { create :line_referential }
  let(:company)               { create :company, line_referential: line_referential }
  let(:workbench)             { create :workbench,
                                       line_referential: line_referential,
                                       stop_area_referential: stop_area_referential }
  let(:referential_metadata)  { create(:referential_metadata, lines: line_referential.lines.limit(3)) }
  let(:referential)           { create :referential,
                                       workbench: workbench,
                                       organisation: workbench.organisation,
                                       metadatas: [referential_metadata]
                              }
  let(:merge)                 { Merge.create!(workbench: referential.workbench, referentials: [referential, referential]) }

  before(:each) do
    10.times { create :stop_area, stop_area_referential: stop_area_referential }
    10.times { create :line, line_referential: line_referential, company: company, network: nil }
    factor = 1
    @stop_points_positions = {}

    referential.switch do
      line_referential.lines.each do |line|
        factor.times do
          stop_areas = stop_area_referential.stop_areas.order("random()").limit(5)
          FactoryGirl.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
        end
      end

      referential.routes.each do |route|
        route.stop_points.each do |sp|
          sp.set_list_position 0
        end
        route.reload.update_checksum!
        factor.times do
          FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
        end
      end

      referential.journey_patterns.each do |journey_pattern|
        @stop_points_positions[journey_pattern.name] = Hash[*journey_pattern.stop_points.map{|sp| [sp.stop_area_id, sp.position]}.flatten]
        factor.times do
          FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: company
        end
      end

      @shared_time_table = FactoryGirl.create :time_table
      @shared_purchase_window = FactoryGirl.create :purchase_window, referential: referential

      referential.vehicle_journeys.each do |vehicle_journey|
        vehicle_journey.time_tables << @shared_time_table
        vehicle_journey.purchase_windows << @shared_purchase_window

        specific_time_table = FactoryGirl.create :time_table
        vehicle_journey.time_tables << specific_time_table
      end
    end
  end

  it "should clone purchase_windows" do
    new_referential = create :referential
    vehicle_journeys = referential.switch do
      Chouette::VehicleJourney.pluck(:checksum).uniq
    end
    new_referential.switch do
      vehicle_journeys.each do |checksum|
        vj = create :vehicle_journey
        Chouette::VehicleJourney.where(id: vj.id).update_all checksum: checksum
      end
    end
    merge.send :merge_purchase_windows, new_referential, referential
    new_referential.switch do
      new_purchase_window = Chouette::PurchaseWindow.find_by name: @shared_purchase_window.name
      expect(new_purchase_window).to be_present
      new_referential.vehicle_journeys.each do |vehicle_journey|
        expect(vehicle_journey.purchase_windows).to eq [new_purchase_window]
      end
    end
  end

  it "should work" do
    merge.merge!

    output = merge.output.current
    output.switch

    # Let's check stop_point positions are respected
    # This should be enforced by the checksum preservation though
    output.journey_patterns.each do |journey_pattern|
      journey_pattern.stop_points.each do |sp|
        expect(sp.position).to eq @stop_points_positions[journey_pattern.name][sp.stop_area_id]
      end
    end

  end

end
