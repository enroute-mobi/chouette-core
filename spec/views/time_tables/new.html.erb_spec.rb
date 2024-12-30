
describe 'time_tables/new', type: :view do
  assign_referential
  let!(:time_table) {  assign(:time_table, build(:time_table)) }

  before do
    allow(view).to receive_messages(current_organisation: referential.organisation)
  end

  # No more test for the form, as it is now managed by React/Redux.
end
