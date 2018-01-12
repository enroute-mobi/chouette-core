FactoryGirl.define do
  factory :custom_field do
    code "code"
    resource_type "VehicleJourney"
    sequence(:name){|n| "custom field ##{n}"}
    field_type "list"
    options( { capacity: "0" } )
  end
end
