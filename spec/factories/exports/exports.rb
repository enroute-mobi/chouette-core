FactoryGirl.define do
  factory :export, class: Export::Base do
    sequence(:name) { |n| "Export #{n}" }
    current_step_id "MyString"
    current_step_progress 1.5
    association :workbench
    association :referential
    status :new
    started_at nil
    ended_at nil
    creator 'rspec'

    after(:build) do |export|
      export.class.skip_callback(:create, :before, :initialize_fields, raise: false)
      export.workgroup = export.workbench.workgroup
    end
  end

  factory :bad_export, class: Export::Base do
    sequence(:name) { |n| "Export #{n}" }
    current_step_id "MyString"
    current_step_progress 1.5
    association :workbench
    association :referential
    file {File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))}
    status :new
    started_at nil
    ended_at nil
    creator 'rspec'

    after(:build) do |export|
      export.class.skip_callback(:create, :before, :initialize_fields, raise: false)
      export.workgroup = export.workbench.workgroup
    end
  end
end
