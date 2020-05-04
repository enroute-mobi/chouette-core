describe PermissionsHelper, type: :helper do
  let(:permissions){ %w(referentials.create referentials.flag_urgent routes.create routes.destroy routes.update routing_constraint_zones.create) }
  let(:permissions_hash){ {
    "referentials"=>["referentials.create", "referentials.flag_urgent"],
    "routes"=>["routes.create", "routes.destroy", "routes.update"],
    "routing_constraint_zones"=>["routing_constraint_zones.create"]
  } }

  describe "#permissions_array_to_hash" do
    it "returns the default title" do
      expect(helper.permissions_array_to_hash permissions).to eq(permissions_hash)
    end
  end
end
