RSpec.describe Chouette::Route, :type => :model do

  subject { create(:route) }

  describe "#stop_points_attributes=" do
      let(:journey_pattern) { create( :journey_pattern, :route => subject )}
      let(:vehicle_journey) { create( :vehicle_journey, :journey_pattern => journey_pattern)}
      def subject_stop_points_attributes
          {}.tap do |hash|
              subject.stop_points.each_with_index { |sp,index| hash[ index.to_s ] = sp.attributes }
          end
      end
      context "route having swapped a new stop" do
          let( :new_stop_point ){build( :stop_point, :route => subject)}
          def added_stop_hash
            subject_stop_points_attributes.tap do |h|
                h["4"] = new_stop_point.attributes.merge( "position" => "4", "_destroy" => "" )
            end
          end
          let!( :new_route_size ){ subject.stop_points.size+1 }

          it "should have added stop_point in route" do
              subject.update_attributes( :stop_points_attributes => added_stop_hash)
              expect(Chouette::Route.find( subject.id ).stop_points.size).to eq(new_route_size)
          end
          it "should have added stop_point in route's journey pattern" do
              subject.update_attributes( :stop_points_attributes => added_stop_hash)
              expect(Chouette::JourneyPattern.find( journey_pattern.id ).stop_points.size).to eq(new_route_size)
          end
          it "should have added stop_point in route's vehicle journey at stop" do
              subject.update_attributes( :stop_points_attributes => added_stop_hash)
              expect(Chouette::VehicleJourney.find( vehicle_journey.id ).vehicle_journey_at_stops.size).to eq(new_route_size)
          end
      end
      context "route having swapped stop" do
          def swapped_stop_hash
            subject_stop_points_attributes.tap do |h|
                h[ "1" ][ "position" ] = "3"
                h[ "3" ][ "position" ] = "1"
            end
          end
          let!( :new_stop_id_list ){ subject.stop_points.map(&:id).tap {|array| array.insert( 1, array.delete_at(3)); array.insert( 3, array.delete_at(2) )} }

          it "should have swap stop_points from route" do
              subject.update_attributes( :stop_points_attributes => swapped_stop_hash)
              expect(Chouette::Route.find(subject.id).stop_points.map(&:id).sort).to eq(new_stop_id_list.sort)
          end
          it "should have swap stop_points from route's journey pattern" do
              subject.update_attributes( :stop_points_attributes => swapped_stop_hash)
              expect(Chouette::JourneyPattern.find( journey_pattern.id ).stop_points.map(&:id).sort).to eq(new_stop_id_list.sort)
          end
          it "should have swap stop_points from route's vehicle journey at stop" do
              subject.update_attributes( :stop_points_attributes => swapped_stop_hash)
              expect(Chouette::VehicleJourney.find( vehicle_journey.id ).vehicle_journey_at_stops.map(&:stop_point_id)).to match_array(new_stop_id_list)
          end
      end
      context "route having a deleted stop" do
          def removed_stop_hash
            subject_stop_points_attributes.tap do |h|
                h[ "1" ][ "_destroy" ] = "1"
            end
          end
          let!( :new_stop_id_list ){ subject.stop_points.map(&:id).tap {|array| array.delete_at(1) } }

          it "should ignore deleted stop_point from route" do
              subject.update_attributes( :stop_points_attributes => removed_stop_hash)
              expect(Chouette::Route.find( subject.id ).stop_points.map(&:id).sort).to eq(new_stop_id_list.sort)
          end
          it "should ignore deleted stop_point from route's journey pattern" do
              subject.update_attributes( :stop_points_attributes => removed_stop_hash)
              expect(Chouette::JourneyPattern.find( journey_pattern.id ).stop_points.map(&:id).sort).to eq(new_stop_id_list.sort)
          end
          it "should ignore deleted stop_point from route's vehicle journey at stop" do
              subject.update_attributes( :stop_points_attributes => removed_stop_hash)
              expect(Chouette::VehicleJourney.find( vehicle_journey.id ).vehicle_journey_at_stops.map(&:stop_point_id).sort).to match_array(new_stop_id_list.sort)
          end
      end
  end

  describe "#stop_points" do
    let(:first_stop_point) { subject.stop_points.first}
    context "#find_by_stop_area" do
      context "when arg is first quay id" do
        it "should return first quay" do
          expect(subject.stop_points.find_by_stop_area( first_stop_point.stop_area_id)).to eq( first_stop_point)
        end
      end
    end

    context 'defaults attributes' do
      let(:new_stop_area) { create :stop_area, kind: 'non_commercial', area_type: 'deposit' }
      let(:new_stop_point) { create :stop_point, stop_area_id: new_stop_area.id }
      it 'should have the correct default attributes' do
        subject.stop_points << new_stop_point
        subject.stop_points.each do |sp|
          # binding.pry
          if sp.stop_area.commercial?
            expect(sp.for_boarding).to eq('normal')
            expect(sp.for_alighting).to eq('normal')
          else
            expect(sp.for_boarding).to eq('forbidden')
            expect(sp.for_alighting).to eq('forbidden')
          end
        end
      end
    end
  end

  describe "#stop_areas" do
    let(:line){ create(:line)}
    let(:route_1){ create(:route, :line => line)}
    let(:route_2){ create(:route, :line => line)}
    it "should retreive all stop_area on route" do
      route_1.stop_areas.each do |sa|
        expect(sa.stop_points.map(&:route_id).uniq).to eq([route_1.id])
      end
    end

    context "when route is looping: last and first stop area are the same" do
      it "should retreive same stop_area one last and first position" do
        route_loop = create(:route, :line => line)
        first_stop = Chouette::StopPoint.where( :route_id => route_loop.id, :position => 0).first
        last_stop = create(:stop_point, :route => route_loop, :position => 4, :stop_area => first_stop.stop_area)

        expect(route_loop.stop_areas.size).to eq(6)
        expect(route_loop.stop_areas.select {|s| s.id == first_stop.stop_area.id}.size).to eq(2)
      end
    end
  end
end

