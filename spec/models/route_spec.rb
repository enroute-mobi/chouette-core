RSpec.describe Chouette::Route, :type => :model do
  it { should have_many(:routing_constraint_zones).dependent(:destroy) }
  subject(:route){ create :route }
  context "the checksum" do
    around { |example| Chouette::ChecksumManager.inline{ example.run }}

    it "should change when a stop is removed" do
      expect{route.stop_points.last.destroy}.to(change {route.reload.checksum})
    end

    it "should change when a rcz changes" do
      rcz = create :routing_constraint_zone, route: route, stop_points: route.stop_points[0..2]
      expect{rcz.stop_points << route.stop_points.last; rcz.save!}.to(change {route.reload.checksum})
    end
  end

  context "when deleting a stop_point" do
    let!(:rcz_should_remain){ create :routing_constraint_zone, route: route, stop_point_ids: route.stop_point_ids[0..2] }
    let!(:rcz_should_disappear){ create :routing_constraint_zone, route: route, stop_point_ids: route.stop_point_ids[0..1] }
    it "should remove empty routing_constraint_zones" do
      route.stop_points[0].destroy
      expect(Chouette::RoutingConstraintZone.where(id: rcz_should_remain.id).exists?).to be_truthy
      expect(Chouette::RoutingConstraintZone.where(id: rcz_should_disappear.id).exists?).to be_falsy
      expect(rcz_should_remain.reload.stop_point_ids.count).to eq 2
    end
  end

  context 'opposite_route' do
    context 'in a work referential' do
      it 'should validate unicity' do
        route = build(:route)
        expect(route).to be_valid

        opposite_route = create(:route, wayback: route.opposite_wayback, line: route.line)
        route.opposite_route = opposite_route
        route.validate
        expect(route).to be_valid

        opposite_route.update opposite_route: create(:route, wayback: route.wayback, line: route.line)
        expect(opposite_route.reload.opposite_route).to be_present
        route.validate
        expect(route).to_not be_valid
      end
    end

    context 'in a merged referential' do
      before(:each) do
        referential.update referential_suite: create(:referential_suite)
        expect(referential.in_referential_suite?).to be_truthy
      end

      it 'should not validate unicity' do
        route = build(:route)
        expect(route).to be_valid

        opposite_route = create(:route, wayback: route.opposite_wayback, line: route.line)
        route.opposite_route = opposite_route
        route.validate
        expect(route).to be_valid

        opposite_route.update opposite_route: create(:route, wayback: route.wayback, line: route.line)
        expect(opposite_route.reload.opposite_route).to be_present
        route.validate
        expect(route).to be_valid
      end
    end
  end

  context "metadatas" do
    it "should be empty at first" do
      expect(Chouette::Route.has_metadata?).to be_truthy
      expect(route.has_metadata?).to be_truthy
      expect(route.metadata.creator_username).to be_nil
      expect(route.metadata.modifier_username).to be_nil
    end

    context "once set" do
      it "should set the correct values" do
        Timecop.freeze(Time.now) do
          route.metadata.creator_username = "john.doe"
          route.save!
          id = route.id
          route = Chouette::Route.find id
          expect(route.metadata.creator_username).to eq "john.doe"
          expect(route.metadata.creator_username_updated_at.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.strftime('%Y-%m-%d %H:%M:%S.%3N')
        end
      end
    end

    context "on update" do
      before do
        route.set_metadata! :creator_username, "john.doe"
      end

      it "should set the correct values" do
        Timecop.freeze(Time.now) do
          id = route.id
          route = Chouette::Route.find id
          route.set_metadata! :creator_username, "john.doe"
          route = Chouette::Route.find id
          expect(route.metadata.creator_username).to eq "john.doe"
          expect(route.metadata.creator_username_updated_at.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.strftime('%Y-%m-%d %H:%M:%S.%3N')
        end
      end
    end

    describe "#merge_metadata_from" do
      let(:source){ create :route }
      let(:metadata){ target.merge_metadata_from(source).metadata }
      let(:target){ create :route }
      before do
        target.metadata.creator_username = "john"
        target.metadata.modifier_username = "john"
      end
      context "when the source has no metadata" do
        it "should do nothing" do
          expect(metadata.creator_username).to eq "john"
          expect(metadata.modifier_username).to eq "john"
        end
      end

      context "when the target has incomplete metadata" do
        before do
          source.metadata.creator_username = "jane"
          target.metadata.delete(:creator_username_updated_at)
        end

        it "should do nothing" do
          expect(metadata.creator_username).to eq "john"
        end
      end

      context "when the source has older metadata" do
        before do
          source.metadata.creator_username = "jane"
          source.metadata.modifier_username = "jane"
          source.metadata.creator_username_updated_at = 1.month.ago
          source.metadata.modifier_username_updated_at = 1.month.ago
        end
        it "should do nothing" do
          expect(metadata.creator_username).to eq "john"
          expect(metadata.modifier_username).to eq "john"
        end
      end

      context "when the source has new metadata" do
        before do
          source.metadata.creator_username = "jane"
          source.metadata.modifier_username = "jane"
          target.metadata.creator_username_updated_at = 1.month.ago
          target.metadata.modifier_username_updated_at = 1.month.ago
        end
        it "should update metadata" do
          expect(metadata.creator_username).to eq "jane"
          expect(metadata.modifier_username).to eq "jane"
        end
      end
    end
  end

  context "when creating stop_points" do
    # Here we tests that acts_as_list does not mess with the positions
    let(:stop_areas){
      4.times.map{create :stop_area}
    }

    it "should set a correct order to the stop_points" do

      order = [0, 3, 2, 1]
      new = Referential.new
      new.name = "mkmkm"
      new.prefix= "mkmkm"
      new.organisation = create(:organisation)
      new.line_referential = create(:line_referential)
      create(:line, line_referential: new.line_referential)
      new.stop_area_referential = create(:stop_area_referential)
      new.objectid_format = :netex
      new.save!
      new.switch
      route = new.routes.new

      route.published_name = route.name = "Route"
      route.line = new.line_referential.lines.last
      order.each_with_index do |position, i|
        _attributes = {
          stop_area: stop_areas[i],
          position: position
        }
        route.stop_points.build _attributes
      end
      route.save
      expect(route).to be_valid
      expect{route.run_callbacks(:commit)}.to_not raise_error
    end
  end
end
