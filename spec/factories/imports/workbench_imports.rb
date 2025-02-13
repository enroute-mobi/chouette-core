FactoryBot.define do
  factory :workbench_import, class: Import::Workbench, parent: :import do
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
  end
end
