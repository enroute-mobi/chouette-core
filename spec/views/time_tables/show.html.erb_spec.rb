
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
  let!(:time_table_combination) {assign(:time_table_combination, TimeTableCombination.new)}

  before do
    allow(view).to receive_messages(current_organisation: referential.organisation)
  end
end
