describe NetworksController do
  describe "routing" do
    it "recognize and generate #show" do
      expect(get( "/workbenches/1/line_referential/networks/2")).to route_to(
        :controller => "networks", :action => "show",
        :workbench_id => "1", :id => "2"
      )
    end
  end
end
