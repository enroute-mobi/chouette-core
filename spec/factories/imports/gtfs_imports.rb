FactoryBot.define do
  factory :gtfs_import, class: Import::Gtfs, parent: :import do
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
    association :parent, factory: :workbench_import
  end
end
