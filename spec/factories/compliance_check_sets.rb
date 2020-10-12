FactoryBot.define do
  factory :compliance_check_set do
    status {:new}
    association :referential
    association :compliance_control_set
    association :workbench

    after(:build) do |ccs|
      ccs.workgroup = ccs.workbench.workgroup
    end
  end
end
