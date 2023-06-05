
describe "/time_tables/show", :type => :view do

  assign_referential
  let!(:time_table) do
    assign(
      :time_table,
      create(:time_table).decorate(context: {
        referential: referential
      })
    )
  end
  let!(:year) { assign(:year, Date.today.cwyear) }

  before do
    allow(view).to receive_messages(current_organisation: referential.organisation)
  end
end
