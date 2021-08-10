RSpec.describe Chouette::ChecksumUpdater do
  def a_checksum
    a_string_matching(/[0-9a-f]{64}/)
  end

  describe "#routes" do
    let(:context) do
      Chouette.create do
        route { routing_constraint_zone }
      end
    end
    let(:referential) { context.referential }
    before { referential.switch }

    let(:routing_constraint_zone) { context.routing_constraint_zone }
    let(:route) { context.route }

    it "computes the RoutingConstraintZone checksum" do
      expect do
        Chouette::ChecksumUpdater.new(referential).routes
        routing_constraint_zone.reload
      end.to change(routing_constraint_zone, :checksum).from(nil).to(a_checksum)
    end

    it "computes the Route checksum" do
      expect do
        Chouette::ChecksumUpdater.new(referential).routes
        route.reload
      end.to change(route, :checksum).from(nil).to(a_string_matching(/[0-9a-f]{64}/))
    end
  end
end
