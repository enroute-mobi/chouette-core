FactoryBot.define do
  factory :import, class: Import::Base do
    sequence(:name) { |n| "Import #{n}" }
    current_step_id {"MyString"}
    current_step_progress {1.5}
    association :workbench
    association :referential
    file {File.open(File.join(Rails.root, 'spec', 'fixtures', 'OFFRE_TRANSDEV_2017030112251.zip'))}
    status {:new}
    started_at {nil}
    ended_at {nil}
    creator {'rspec'}
  end

  factory :bad_import, class: Import::Base do
    sequence(:name) { |n| "Import #{n}" }
    current_step_id {"MyString"}
    current_step_progress {1.5}
    association :workbench
    association :referential
    file {File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))}
    status {:new}
    started_at {nil}
    ended_at {nil}
    creator {'rspec'}
  end
end
