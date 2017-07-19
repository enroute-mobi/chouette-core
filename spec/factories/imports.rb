FactoryGirl.define do
  factory :import do
    sequence(:name) { |n| "Import #{n}" }
    current_step_id "MyString"
    current_step_progress 1.5
    association :workbench
    association :referential
    file {File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))}
    status :new
    started_at nil
    ended_at nil

    factory :netex_import do
      type 'NetexImport'
      file {Rails.root.join('spec', 'fixtures', 'terminated_job.json')}
    end
  end
end
