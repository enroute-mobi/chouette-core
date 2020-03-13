
describe "/line_referentials/show", :type => :view do

  let(:line_referential) do
    line_referential = create(:line_referential)
    assign :line_referential, line_referential.decorate
  end

  before :each do
    controller.request.path_parameters[:id] = line_referential.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
    allow(view).to receive(:resource).and_return(line_referential)
    allow(view).to receive(:resource_class).and_return(line_referential.class)

    render  template: "line_referentials/show", layout: "layouts/application"
  end

  it "should not present syncing infos and button" do
    expect(rendered).to_not have_selector("a[href=\"#{view.sync_line_referential_path(line_referential)}\"]")
  end

  with_permission "line_referentials.synchronize" do
    it "should present syncing infos and button" do
      expect(rendered).to have_selector("a[href=\"#{view.sync_line_referential_path(line_referential)}\"]", count: 1)
    end
  end
end
