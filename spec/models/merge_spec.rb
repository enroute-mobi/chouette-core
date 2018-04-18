require "rails_helper"

RSpec.describe Merge do

  it "should work" do
    stop_area_referential = FactoryGirl.create :stop_area_referential
    10.times { FactoryGirl.create :stop_area, stop_area_referential: stop_area_referential }

    line_referential = FactoryGirl.create :line_referential
    company = FactoryGirl.create :company, line_referential: line_referential
    10.times { FactoryGirl.create :line, line_referential: line_referential, company: company, network: nil }

    workbench = FactoryGirl.create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential

    referential_metadata = FactoryGirl.create(:referential_metadata, lines: line_referential.lines.limit(3))

    referential = FactoryGirl.create :referential,
                                      workbench: workbench,
                                      organisation: workbench.organisation,
                                      metadatas: [referential_metadata]

    factor = 1
    stop_points_positions = {}

    routing_constraint_zones = {}

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
        checksum = route.checksum
        routing_constraint_zones[route.id] = {}
        2.times do |i|
          constraint_zone = create(:routing_constraint_zone, route_id: route.id)
          if i > 0
            constraint_zone.update stop_points: constraint_zone.stop_points[0...-1]
          end
          routing_constraint_zones[route.id][constraint_zone.checksum] = constraint_zone
        end

        route.reload.update_checksum!

        expect(route.reload.checksum).to_not eq checksum
        factor.times do
          FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
        end
      end

      referential.journey_patterns.each do |journey_pattern|
        stop_points_positions[journey_pattern.name] = Hash[*journey_pattern.stop_points.map{|sp| [sp.stop_area_id, sp.position]}.flatten]
        factor.times do
          FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: company
        end
      end

      shared_time_table = FactoryGirl.create :time_table

      referential.vehicle_journeys.each do |vehicle_journey|
        vehicle_journey.time_tables << shared_time_table

        specific_time_table = FactoryGirl.create :time_table
        vehicle_journey.time_tables << specific_time_table
        vehicle_journey.update ignored_routing_contraint_zone_ids: routing_constraint_zones[vehicle_journey.route.id].values.map(&:id)
      end

    end

    merge = Merge.create!(workbench: referential.workbench, referentials: [referential, referential])
    merge.merge!

    output = merge.output.current
    output.switch

    output.routes.each do |route|
      stop_points = nil
      old_route = nil
      referential.switch do
        old_route = Chouette::Route.find_by(checksum: route.checksum)
        stop_points = {}
        old_route.routing_constraint_zones.each do |constraint_zone|
          stop_points[constraint_zone.checksum] = constraint_zone.stop_points.map(&:registration_number)
        end
      end
      routing_constraint_zones[old_route.id].each do |checksum, constraint_zone|
        new_constraint_zone = route.routing_constraint_zones.where(checksum: checksum).last
        expect(new_constraint_zone).to be_present
        expect(new_constraint_zone.stop_points.map(&:registration_number)).to eq stop_points[checksum]
      end

      route.vehicle_journeys.each do |vehicle_journey|
        expect(vehicle_journey.ignored_routing_contraint_zones.size).to eq vehicle_journey.ignored_routing_contraint_zone_ids.size
      end
    end

    # Let's check stop_point positions are respected
    # This should be enforced by the checksum preservation though
    output.journey_patterns.each do |journey_pattern|
      journey_pattern.stop_points.each do |sp|
        expect(sp.position).to eq stop_points_positions[journey_pattern.name][sp.stop_area_id]
      end
    end

    expect(output.state).to eq :ready
    expect(referential.reload.state).to eq :archived

  end

end
