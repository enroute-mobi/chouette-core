require 'spec_helper'

describe Chouette::JourneyPattern, :type => :model do

  # context 'validate minimum stop_points size' do
  #   let(:journey_pattern) { create :journey_pattern }
  #   let(:stop_points) { journey_pattern.stop_points }
  #
  #   it 'should be valid if it has at least two sp' do
  #     journey_pattern.stop_points.first(stop_points.size - 2).each do |sp|
  #       journey_pattern.stop_points.delete(sp)
  #     end
  #     expect(journey_pattern).to be_valid
  #   end
  #
  #   it 'should not be valid if it has less then two sp' do
  #     journey_pattern.stop_points.first(stop_points.size - 1).each do |sp|
  #       journey_pattern.stop_points.delete(sp)
  #     end
  #     expect(journey_pattern).to_not be_valid
  #     expect(journey_pattern.errors).to have_key(:stop_points)
  #   end
  #
  #   it 'should only validate on update' do
  #     jp = build(:journey_pattern_common)
  #     expect(jp).to be_valid
  #   end
  # end

  describe "state_update" do
    def journey_pattern_to_state jp
      jp.attributes.slice('name', 'published_name', 'registration_number').tap do |item|
        item['object_id']   = jp.objectid
        item['stop_points'] = jp.stop_points.map do |sp|
          { 'id' => sp.stop_area_id }
        end
      end
    end

    let(:route) { create :route }
    let(:journey_pattern) { create :journey_pattern, route: route }
    let(:state) { journey_pattern_to_state(journey_pattern) }

    it 'should delete unchecked stop_points' do
      # Of 5 stop_points 2 are checked
      state['stop_points'].take(2).each{|sp| sp['checked'] = true}
      journey_pattern.state_stop_points_update(state)
      expect(journey_pattern.stop_points.count).to eq(2)
    end

    it 'should attach checked stop_points' do
      # Make sure journey_pattern has no stop_points
      state['stop_points'].each{|sp| sp['checked'] = false}
      journey_pattern.state_stop_points_update(state)
      expect(journey_pattern.reload.stop_points).to be_empty

      state['stop_points'].each{|sp| sp['checked'] = true}
      journey_pattern.state_stop_points_update(state)

      expect(journey_pattern.reload.stop_points.count).to eq(5)
    end

    it 'should create journey_pattern' do
      new_state = journey_pattern_to_state(build(:journey_pattern, objectid: nil, route: route))
      Chouette::JourneyPattern.state_create_instance route, new_state
      expect(new_state['object_id']).to be_truthy
      expect(new_state['new_record']).to be_truthy
    end

    it 'should delete journey_pattern' do
      state['deletable'] = true
      collection = [state]
      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to change{Chouette::JourneyPattern.count}.from(1).to(0)

      expect(collection).to be_empty
    end

    it 'should delete multiple journey_pattern' do
      collection = 5.times.collect{journey_pattern_to_state(create(:journey_pattern, route: route))}
      collection.map{|i| i['deletable'] = true}

      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to change{Chouette::JourneyPattern.count}.from(5).to(0)
    end

    it 'should validate journey_pattern on update' do
      journey_pattern.name = ''
      collection = [state]
      Chouette::JourneyPattern.state_update route, collection
      expect(collection.first['errors']).to have_key(:name)
    end

    it 'should validate journey_pattern on create' do
      new_state  = journey_pattern_to_state(build(:journey_pattern, name: '', objectid: nil, route: route))
      collection = [new_state]
      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to_not change{Chouette::JourneyPattern.count}

      expect(collection.first['errors']).to have_key(:name)
      expect(collection.first).to_not have_key('object_id')
    end

    it 'should not save any journey_pattern of collection if one is invalid' do
      journey_pattern.name = ''
      valid_state   = journey_pattern_to_state(build(:journey_pattern, objectid: nil, route: route))
      invalid_state = journey_pattern_to_state(journey_pattern)
      collection    = [valid_state, invalid_state]

      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to_not change{Chouette::JourneyPattern.count}

      expect(collection.first).to_not have_key('object_id')
    end

    it 'should create journey_pattern' do
      new_state = journey_pattern_to_state(build(:journey_pattern, objectid: nil, route: route))
      Chouette::JourneyPattern.state_create_instance route, new_state
      expect(new_state['object_id']).to be_truthy
      expect(new_state['new_record']).to be_truthy
    end

    it 'should delete journey_pattern' do
      state['deletable'] = true
      collection = [state]
      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to change{Chouette::JourneyPattern.count}.from(1).to(0)

      expect(collection).to be_empty
    end

    it 'should delete multiple journey_pattern' do
      collection = 5.times.collect{journey_pattern_to_state(create(:journey_pattern, route: route))}
      collection.map{|i| i['deletable'] = true}

      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to change{Chouette::JourneyPattern.count}.from(5).to(0)
    end

    it 'should validate journey_pattern on update' do
      journey_pattern.name = ''
      collection = [state]
      Chouette::JourneyPattern.state_update route, collection
      expect(collection.first['errors']).to have_key(:name)
    end

    it 'should validate journey_pattern on create' do
      new_state  = journey_pattern_to_state(build(:journey_pattern, name: '', objectid: nil, route: route))
      collection = [new_state]
      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to_not change{Chouette::JourneyPattern.count}

      expect(collection.first['errors']).to have_key(:name)
      expect(collection.first).to_not have_key('object_id')
    end

    it 'should not save any journey_pattern of collection if one is invalid' do
      journey_pattern.name = ''
      valid_state   = journey_pattern_to_state(build(:journey_pattern, objectid: nil, route: route))
      invalid_state = journey_pattern_to_state(journey_pattern)
      collection    = [valid_state, invalid_state]

      expect {
        Chouette::JourneyPattern.state_update route, collection
      }.to_not change{Chouette::JourneyPattern.count}

      expect(collection.first).to_not have_key('object_id')
    end
  end

  describe "#stop_point_ids" do
    context "for a journey_pattern using only route's stop on odd position" do
      let!(:journey_pattern){ create( :journey_pattern_odd)}
      let!(:vehicle_journey){ create( :vehicle_journey_odd, :journey_pattern => journey_pattern)}

      # workaroud
      #subject { journey_pattern}
      subject { Chouette::JourneyPattern.find(vehicle_journey.journey_pattern_id)}

      context "when a all route's stop have been removed from journey_pattern" do
        before(:each) do
          subject.stop_point_ids = []
        end
        it "should remove all vehicle_journey_at_stop" do
          vjas_stop_ids = Chouette::VehicleJourney.find(vehicle_journey.id).vehicle_journey_at_stops
          expect(vjas_stop_ids.count).to eq(0)
        end
        it "should keep departure and arrival shortcut up to date to nil" do
          expect(subject.arrival_stop_point_id).to be_nil
          expect(subject.departure_stop_point_id).to be_nil
        end
      end

      context "when a route's stop has been removed from journey_pattern" do
        let!(:last_stop_id){ subject.stop_point_ids.last}
        before(:each) do
          subject.stop_point_ids = subject.stop_point_ids - [last_stop_id]
        end
        it "should remove vehicle_journey_at_stop for last stop" do
          vjas_stop_ids = Chouette::VehicleJourney.find(vehicle_journey.id).vehicle_journey_at_stops.map(&:stop_point_id)
          expect(vjas_stop_ids.count).to eq(subject.stop_point_ids.size)
          expect(vjas_stop_ids).not_to include( last_stop_id)
        end
        it "should keep departure and arrival shortcut up to date" do
          ordered = subject.stop_points.sort { |a,b| a.position <=> b.position}

          expect(subject.arrival_stop_point_id).to eq(ordered.last.id)
          expect(subject.departure_stop_point_id).to eq(ordered.first.id)
        end
      end

      context "when a route's stop has been added in journey_pattern" do
        let!(:new_stop){ subject.route.stop_points[1]}
        before(:each) do
          subject.stop_point_ids = subject.stop_point_ids + [new_stop.id]
        end
        it "should add a new vehicle_journey_at_stop for that stop" do
          vjas_stop_ids = Chouette::VehicleJourney.find(vehicle_journey.id).vehicle_journey_at_stops.map(&:stop_point_id)
          expect(vjas_stop_ids.count).to eq(subject.stop_point_ids.size)
          expect(vjas_stop_ids).to include( new_stop.id)
        end
        it "should keep departure and arrival shortcut up to date" do
          ordered = subject.stop_points.sort { |a,b| a.position <=> b.position}

          expect(subject.arrival_stop_point_id).to eq(ordered.last.id)
          expect(subject.departure_stop_point_id).to eq(ordered.first.id)
        end
      end
    end
  end
end
