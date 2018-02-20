require 'spec_helper'

describe Chouette::RoutingConstraintZone, type: :model do

  subject { create(:routing_constraint_zone) }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :route_id }
  # shoulda matcher to validate length of array ?
  xit { is_expected.to validate_length_of(:stop_point_ids).is_at_least(2) }
  it { is_expected.to be_versioned }

  describe 'checksum' do
    it_behaves_like 'checksum support'
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

    xit 'validates that not all stop points from the route are selected' do
      routing_constraint_zone.stop_points = routing_constraint_zone.route.stop_points
      expect {
        subject.save!
      }.to raise_error(ActiveRecord::RecordInvalid)
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

end
