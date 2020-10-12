FactoryBot.define do
  factory :custom_field do
    code {"code"}
    resource_type {"VehicleJourney"}
    sequence(:name){|n| "custom field ##{n}"}
    field_type {"integer"}
    options {{ capacity: "0" }}
    workgroup { Referential.find_by!(name: "first").workgroup }
  end
end
