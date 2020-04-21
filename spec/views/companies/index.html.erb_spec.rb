
RSpec.describe "/companies/index", :type => :view do

  let!(:line_referential) { assign :line_referential, create(:line_referential) }
  let(:context){{referential: line_referential}}
  let!(:companies) do
    assign :companies, build_paginated_collection(:company, CompanyDecorator, line_referential: line_referential, context: context)
  end
  let!(:search) { assign :q, Ransack::Search.new(Chouette::Company) }

  # Fixme #1795
  # it "should render a show link for each group" do
  #   render
  #   puts rendered
  #
  #   companies.each do |company|
  #     expect(rendered).to have_selector("a[href='#{view.line_referential_company_path(line_referential, company)}']")
  #   end
  # end

  # Fixme #1795 @see CompanyPolicy
  # it "should render a link to create a new group" do
  #   render
  #   expect(view.content_for(:sidebar)).to have_selector(".actions a[href='#{new_line_referential_company_path(line_referential)}']")
  # end

  before(:each) do
    allow(view).to receive(:collection).and_return(companies)
    allow(view).to receive(:decorated_collection).and_return(companies)
    allow(view).to receive(:current_referential).and_return(line_referential)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class){ Chouette::Company }
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"

    before(:each){
      render template: "companies/index", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "companies/index" }

    %w(create update destroy).each do |p|
      with_permission "companies.#{p}" do
        it { should match_actions_links_snapshot "companies/index_#{p}" }
      end
    end
  end

end
