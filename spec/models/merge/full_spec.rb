RSpec.describe Merge do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential){
    ref = create :referential, workbench: workbench, organisation: workbench.organisation
    create(:referential_metadata, lines: line_referential.lines.limit(3), referential: ref)
    ref.reload
  }
  let(:referential_metadata){ referential.metadatas.last }

  before(:each) do
    4.times { create :line, line_referential: line_referential, company: company, network: nil }
    10.times { create :stop_area, stop_area_referential: stop_area_referential }
  end

  context "with a full context" do
    let(:factor){ 2 }
    before(:each) do
      @stop_points_positions = {}
      @routing_constraint_zones = {}

      footnotes = Hash.new { |h,k| h[k] = [nil] }

      Chouette::ChecksumManager.inline do
        referential.switch do
          line_referential.lines.each do |line|
            factor.times do
              stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(5)
              FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
            end
            # Loop
            stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(5)
            route = FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
            route.stop_points.create stop_area: stop_areas.first, position: route.stop_points.size
            jp = route.full_journey_pattern
            expect(route.stop_points.uniq.count).to eq route.stop_areas.uniq.count + 1
            expect(jp.stop_points.uniq.count).to eq jp.stop_areas.uniq.count + 1

            factor.times do
              footnotes[line.id] << FactoryBot.create(:footnote, line: line)
            end
          end

          referential.routes.each_with_index do |route, index|
            route.stop_points.each do |sp|
              sp.set_list_position 0
            end
            route.reload.update_checksum!
            checksum = route.checksum
            @routing_constraint_zones[route.id] = {}
            factor.times do |i|
              constraint_zone = create(:routing_constraint_zone, route_id: route.id)
              if i > 0
                constraint_zone.update stop_points: constraint_zone.stop_points[0...-1]
              end
              @routing_constraint_zones[route.id][constraint_zone.checksum] = constraint_zone
            end

            if index.even?
              route.wayback = :outbound
            else
              route.update_column :wayback, :inbound
              route.opposite_route = route.opposite_route_candidates.sample
            end

            route.save!

            route.reload.update_checksum!
            expect(route.reload.checksum).to_not eq checksum

            factor.times do
              FactoryBot.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
            end
          end

          referential.journey_patterns.each do |journey_pattern|
            @stop_points_positions[journey_pattern.name] = Hash[*journey_pattern.stop_points.map{|sp| [sp.position, sp.stop_area_id]}.flatten]
            factor.times do
              FactoryBot.create :vehicle_journey, journey_pattern: journey_pattern, company: company
            end
          end

          shared_time_table = FactoryBot.create :time_table

          distant_future_table = FactoryBot.create :time_table, dates_count: 0, periods_count: 0, comment: "distant_future_table"
          distant_future_table.periods << create(:time_table_period, time_table: distant_future_table, period_start: 10.years.from_now, period_end: 11.years.from_now)
          @distant_future_table_name = distant_future_table.comment
          one_day_remanining_table = FactoryBot.create :time_table, dates_count: 0, periods_count: 0, comment: "one_day_remanining"
          period_start = referential_metadata.periodes.last.max
          one_day_remanining_table.periods << create(:time_table_period, time_table: one_day_remanining_table, period_start: period_start, period_end: period_start+1.week)
          @one_day_remanining_table_name = one_day_remanining_table.comment

          referential.vehicle_journeys.each do |vehicle_journey|
            vehicle_journey.time_tables << shared_time_table

            specific_time_table = FactoryBot.create :time_table
            vehicle_journey.time_tables << specific_time_table
            vehicle_journey.time_tables << distant_future_table
            vehicle_journey.time_tables << one_day_remanining_table

            if footnote = footnotes[vehicle_journey.route.line.id].sample
              vehicle_journey.footnotes << footnote
            end

            vehicle_journey.update_checksum!
          end
        end
      end
    end

    context "with timetables defined outside of the referential metadatas" do
      let(:factor){ 1 }

      it "should clean empty time_tables and create dates with single-day periods" do
        merge = Merge.create!(
          workbench: referential.workbench,
          referentials: [referential, referential],
          creator: 'test'
        )
        merge.merge!
        output = merge.output.current
        output.switch

        expect(Chouette::TimeTable.where("comment LIKE '%#{@distant_future_table_name}'").count).to be_zero
        Chouette::TimeTable.where("comment LIKE '%#{@one_day_remanining_table_name}'").each do |tt|
          expect(tt.periods).to be_empty
          expect(tt.dates.count).to eq 1
          date = tt.dates.last
          expect(date.in_out).to be_truthy
          expect(date.date).to eq referential_metadata.periodes.last.max
        end
      end
    end

    it "should work" do
      merge = Merge.create!(workbench: referential.workbench, referentials: [referential], creator: 'test')
      expect(merge).to receive(:clean_previous_operations)
      expect{ merge.merge }.to change { Delayed::Job.count}.by 1
      merge.merge!

      expect(merge.status). to eq :successful

      output = merge.output.current

      expect(merge.new_id). to eq output.id

      output.switch

      output.routes.each do |route|
        stop_points = nil
        old_route = nil
        old_opposite_route = nil
        referential.switch do
          old_route = Chouette::Route.find_by(checksum: route.checksum)
          stop_points = {}
          old_route.routing_constraint_zones.each do |constraint_zone|
            stop_points[constraint_zone.checksum] = constraint_zone.stop_points.map(&:registration_number)
          end
          old_opposite_route = old_route.opposite_route
        end
        @routing_constraint_zones[old_route.id].each do |checksum, constraint_zone|
          new_constraint_zone = route.routing_constraint_zones.where(checksum: checksum).last
          expect(new_constraint_zone).to be_present
          expect(new_constraint_zone.stop_points.map(&:registration_number)).to eq stop_points[checksum]
        end

        expect(route.opposite_route&.checksum).to eq(old_opposite_route&.checksum)
      end

      # Let's check stop_point positions are respected
      # This should be enforced by the checksum preservation though
      output.journey_patterns.each do |journey_pattern|
        journey_pattern.stop_points.each do |sp|
          expect(sp.stop_area_id).to eq @stop_points_positions[journey_pattern.name][sp.position]
        end
      end

      expect(output.state).to eq :active
      expect(referential.reload.state).to eq :archived
      expect(referential.reload.ready?).to be_truthy
    end
  end
end
