
describe CompaniesController do
  describe "routing" do
    it "not recognize #routes" do
      expect(get( "/line_referentials/1/companies/2/routes")).not_to route_to(
        :controller => "companies", :action => "routes",
        :line_referential_id => "1", :id => "2"
      )
    end
    it "not recognize #lines" do
      expect(get( "/line_referentials/1/companies/2/lines")).not_to route_to(
        :controller => "companies", :action => "lines",
        :line_referential_id => "1", :id => "2"
      )
    end
    it "recognize and generate #show" do
      expect(get( "/line_referentials/1/companies/2")).to route_to(
        :controller => "companies", :action => "show",
        :line_referential_id => "1", :id => "2"
      )
    end
  end
end

