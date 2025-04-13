FactoryBot.define do
  factory :import, class: Import::Base do
    sequence(:name) { |n| "Import #{n}" }
    current_step_id {"MyString"}
    current_step_progress {1.5}
    association :workbench
    association :referential
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
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
    file { file_fixture('terminated_job.json').open }
    status {:new}
    started_at {nil}
    ended_at {nil}
    creator {'rspec'}
  end
end
