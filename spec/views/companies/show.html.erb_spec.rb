
describe "/companies/show", :type => :view do

  let!(:company) { c = create(:company); assign(:company, c.decorate(context: {referential: c.line_referential})) }
  let!(:line_referential) { assign :line_referential, company.line_referential }

  # it "should display a map with class 'company'" do
  #   render
  #  expect(rendered).to have_selector("#map", :class => 'company')
  # end

  before(:each) do
    allow(view).to receive(:current_referential).and_return(line_referential)
    allow(view).to receive(:resource).and_return(company)
    allow(view).to receive(:resource_class).and_return(Chouette::Company)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    controller.request.path_parameters[:id] = company.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"
    set_invariant "company.object.id", "909"
    set_invariant "company.object.name", "Company Name"
    set_invariant "company.object.updated_at", "2018/01/23".to_time

    before(:each){
      render template: "companies/show", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "companies/show" }

    %w(create update destroy).each do |p|
      with_permission "companies.#{p}" do
        it { should match_actions_links_snapshot "companies/show_#{p}" }
      end
    end
  end
end
