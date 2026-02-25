FactoryBot.define do
  factory :gtfs_import, class: Import::Gtfs, parent: :import do
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }

    transient do
      parent_tags { [] }
    end
    parent { association :workbench_import, tags: parent_tags }
  end
end
