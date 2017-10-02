FactoryGirl.define do
  factory :line_control_route, class: 'LineControl::Route' do
    association :compliance_control_set
    association :compliance_control_block
  end

end
