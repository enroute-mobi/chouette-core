require 'spec_helper'

describe Chouette::RoutingConstraintZone, type: :model do

  subject(:routing_constraint_zone) { create(:routing_constraint_zone) }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :route_id }
  # shoulda matcher to validate length of array ?
  xit { is_expected.to validate_length_of(:stop_point_ids).is_at_least(2) }


  describe 'checksum' do
    it_behaves_like 'checksum support'

    it "changes when a stop_point is updated" do
      stop_point = subject.stop_points.first

      expect{stop_point.update(position: subject.stop_points.last.position + 1)}.to change{subject.reload.checksum}
    end
  end

  describe 'validations' do
    it 'validates the presence of stop_point_ids' do
      expect {
        subject.update!(stop_point_ids: [])
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'validates that stop points belong to the route' do
      route = create(:route)
      expect {
        subject.update!(route_id: route.id)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'validates that not all stop points from the route are selected' do
      routing_constraint_zone.stop_points = routing_constraint_zone.route.stop_points
      expect {
        subject.save!
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'allows that all stop points from the route are selected' do
      routing_constraint_zone.stop_points = routing_constraint_zone.route.stop_points
      routing_constraint_zone.allow_entire_journey = true
      expect {
        subject.save!
      }.to_not raise_error
    end
  end

  describe 'deleted stop areas' do
    it 'does not have them in stop_area_ids' do
      stop_point = subject.route.stop_points.last
      subject.stop_points << stop_point
      subject.save!
      subject.route.stop_points.last.destroy!
      expect(subject.stop_points.map(&:id)).not_to include(stop_point.id)
    end
  end

  describe 'stop_points' do
    it 'should respect the positions' do
      stop_points = subject.stop_points.sort_by(&:position).reverse
      subject.stop_points = stop_points
      subject.save!
      expect(subject.stop_points).to eq stop_points.sort_by(&:position)
    end
  end
end
