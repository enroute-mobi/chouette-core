RSpec.describe GroupOfLinesController do
  describe "routing" do
    it "not recognize #routes" do
      expect(get( "/line_referentials/1/group_of_lines/2/routes")).not_to route_to(
        :controller => "group_of_lines", :action => "routes",
        :line_referential_id => "1", :id => "2"
      )
    end
    it "not recognize #lines" do
      expect(get( "/line_referentials/1/group_of_lines/2/lines")).not_to route_to(
        :controller => "group_of_lines", :action => "lines",
        :line_referential_id => "1", :id => "2"
      )
    end
    it "recognize and generate #show" do
      expect(get( "/line_referentials/1/group_of_lines/2")).to route_to(
        :controller => "group_of_lines", :action => "show",
        :line_referential_id => "1", :id => "2"
      )
    end
  end
end

