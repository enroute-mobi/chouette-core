
describe 'time_tables/edit', type: :view do
  assign_referential
  let!(:time_table) { assign(:time_table, create(:time_table) ) }
  # No more test for the form, as it is now managed by React/Redux.
end
