FactoryBot.define do
  factory :line_control_route, class: 'LineControl::Route' do
    association :compliance_control_set
  end
end
