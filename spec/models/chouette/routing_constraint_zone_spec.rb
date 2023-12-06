describe Chouette::RoutingConstraintZone, type: :model do

  subject { create(:routing_constraint_zone) }
  let(:route){ subject.route }

  it { is_expected.to belong_to(:route).required(true) }
  it { is_expected.to validate_presence_of :name }
  # shoulda matcher to validate length of array ?
  xit { is_expected.to validate_length_of(:stop_point_ids).is_at_least(2) }


  describe 'checksum' do
    it_behaves_like 'checksum support'

    context "when ChecksumManager is inline" do
      around { |example| Chouette::ChecksumManager.inline{ example.run }}


      it "changes when a stop_point is updated" do
        stop_point = subject.stop_points.first

        expect{stop_point.update(position: subject.stop_points.last.position + 1)}.to(change{subject.reload.checksum})
      end
    end
  end

  describe 'opposite_zone' do
    it 'should be nil' do
      expect(subject.opposite_zone).to be_nil
    end

    context 'with an opposite route' do
      let!(:opposite_route) do
        r = create :route, line: route.line, wayback: subject.route.opposite_wayback, stop_points_count: 0
        route.opposite_route = r
        route.save
        route.stop_points.reverse.each do |stop_point|
          r.stop_points.create stop_area: stop_point.stop_area
        end
        r
      end

      it 'should be false' do
        expect(subject.route.reload.opposite_route).to eq opposite_route
        expect(subject.opposite_zone).to be_nil
      end

      context 'with a routing_constraint_zone' do
        let!(:opposite_routing_constraint_zone){ create :routing_constraint_zone, route: opposite_route, stop_point_ids: opposite_route.stop_point_ids[0..1] }

        before(:each) { opposite_route.reload }

        it 'should be false' do
          expect(subject.opposite_zone).to be_nil
        end

        context 'sharing some stops' do
          before do
            opposite_routing_constraint_zone.stop_points << opposite_route.stop_points.find{ |sp| sp.stop_area_id == subject.stop_points.first.stop_area_id }
            opposite_routing_constraint_zone.save
          end

          it 'should be false' do
            expect(subject.opposite_zone).to be_nil
          end
        end

        context 'with extra stops' do
          before do
            opposite_routing_constraint_zone.stop_points = opposite_route.stop_points
            opposite_routing_constraint_zone.save
          end

          it 'should be false' do
            expect(subject.stop_points.count).to_not eq opposite_routing_constraint_zone.stop_points.count
            expect(subject.opposite_zone).to be_nil
          end
        end

        context 'with the same stops' do
          before do
            opposite_routing_constraint_zone.stop_points = []
            subject.stop_points.each do |stop_point|
              opposite_routing_constraint_zone.stop_points << opposite_route.stop_points.find{ |sp| sp.stop_area_id == stop_point.stop_area_id }
            end
            opposite_routing_constraint_zone.save
          end

          it 'should be present' do
            expect(subject.stop_points.count).to eq opposite_routing_constraint_zone.stop_points.count
            expect(subject.opposite_zone).to eq opposite_routing_constraint_zone
          end
        end
      end
    end
  end
  describe 'can_create_opposite_zone?' do
    it 'should be false' do
      expect(subject.can_create_opposite_zone?).to be_falsy
    end

    context 'with an opposite route' do
      let!(:opposite_route) do
        r = create :route, line: route.line, wayback: subject.route.opposite_wayback
        route.opposite_route = r
        route.save
        r
      end

      it 'should be false' do
        expect(subject.route.reload.opposite_route).to eq opposite_route
        expect(subject.can_create_opposite_zone?).to be_falsy
      end

      context 'sharing some stops' do
        before do
          opposite_route.stop_points.create stop_area: subject.stop_points.first.stop_area
        end
        it 'should be false' do
          expect(subject.can_create_opposite_zone?).to be_falsy
        end
      end

      context 'sharing all the stops' do
        before do
          subject.stop_points.each do |stop_point|
            opposite_route.stop_points.create stop_area: stop_point.stop_area
          end
          # we throw a loop in the mix
          opposite_route.stop_points.create stop_area: subject.stop_points.first.stop_area
        end

        it 'should be true' do
          expect(subject.can_create_opposite_zone?).to be_truthy
        end

        context 'with an opposite_zone existing' do
          before do
            allow(subject).to receive(:opposite_zone){ true }
          end

          it 'should be false' do
            expect(subject.can_create_opposite_zone?).to be_falsy
          end
        end
      end
    end
  end

  describe 'validations' do
    it 'validates the presence of stop_point_ids' do
      expect {
        subject.update!(stop_point_ids: [])
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'validates the number of stop_point_ids' do
      expect {
        subject.update!(stop_point_ids: [subject.route.stop_points[0]])
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

  describe 'stop_points' do
    it 'should respect the positions' do
      stop_points = subject.stop_points.sort_by(&:position).reverse
      subject.stop_points = stop_points
      subject.save!
      expect(subject.stop_points).to eq stop_points.sort_by(&:position)
    end
  end
end
