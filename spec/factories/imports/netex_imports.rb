FactoryBot.define do
  factory :netex_import, class: Import::Netex, parent: :import do
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }

    transient do
      parent_tags { [] }
    end
    parent { association :workbench_import, tags: parent_tags }
  end
end
