RSpec.shared_context 'with an exportable referential' do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3)) }
  let(:referential){
    create :referential,
    workbench: workbench,
    organisation: workbench.organisation,
    metadatas: [referential_metadata]
  }

  before(:each) do
    2.times { create :line, line_referential: line_referential, company: company, network: nil }
    8.times { create :stop_area, stop_area_referential: stop_area_referential }
    2.times { create :stop_area,
      stop_area_referential: stop_area_referential,
      kind: "non_commercial",
      area_type: Chouette::AreaType.non_commercial.sample
    }
  end
end

RSpec.shared_context 'with exportable journeys' do
  before(:each) do
    factor = 2

    # Create two levels parents stop_areas
    6.times do |index|
      sa = referential.stop_areas.sample
      new_parent = FactoryGirl.create :stop_area, stop_area_referential: stop_area_referential
      sa.parent = new_parent
      sa.save
      if index.even?
        new_parent.parent = FactoryGirl.create :stop_area, stop_area_referential: stop_area_referential
        new_parent.save
      end
    end

    referential.switch do
      line_referential.lines.each do |line|
        # 2*2 routes with 5 stop_areas each
        factor.times do
          stop_areas = stop_area_referential.stop_areas.order("random()").limit(5)
          FactoryGirl.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
        end
      end

      referential.routes.each_with_index do |route, index|
        route.stop_points.each do |sp|
          sp.set_list_position 0
        end

        if index.even?
          route.wayback = :outbound
        else
          route.update_column :wayback, :inbound
          route.opposite_route = route.opposite_route_candidates.sample
        end

        route.save!

        # 4*2 journey_pattern with 3 stop_points each
        factor.times do
          FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
        end
      end

      # 8*2 vehicle_journey
      referential.journey_patterns.each do |journey_pattern|
        factor.times do
          FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: company
        end
      end

      # 16+1 different time_tables
      shared_time_table = FactoryGirl.create :time_table

      referential.vehicle_journeys.each do |vehicle_journey|
        vehicle_journey.time_tables << shared_time_table
        specific_time_table = FactoryGirl.create :time_table
        vehicle_journey.time_tables << specific_time_table
      end
    end
  end
end

RSpec.configure do |conf|
  conf.include_context 'with an exportable referential', type: :with_exportable_referential
end
