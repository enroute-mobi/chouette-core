FactoryGirl.define do
  factory :clean_up do
    referential
    begin_date { Date.today}
    end_date   { Date.today + 1.month }
    date_type  { :before }
  end
end
