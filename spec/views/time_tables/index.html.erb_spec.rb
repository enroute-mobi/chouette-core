
describe "/time_tables/index", :type => :view do

  assign_referential
  let!(:time_tables) { assign :time_tables, Array.new(2){ create(:time_table) }.paginate }
  let!(:search) { assign :q, Ransack::Search.new(Chouette::TimeTable) }

  before do
    allow(view).to receive_messages(current_organisation: referential.organisation)
  end

  # it "should render a show link for each group" do
  #   render
  #   time_tables.each do |time_table|
  #     expect(rendered).to have_selector("a[href='#{view.workbench_referential_time_table_path(current_workbench, referential, time_table)}']", :text => time_table.comment)
  #   end
  # end
  #
  # it "should render a link to create a new group" do
  #   render
  #   expect(rendered).to have_selector("a[href='#{new_referential_time_table_path(referential)}']")
  # end

end
