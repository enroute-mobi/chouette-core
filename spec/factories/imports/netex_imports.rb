FactoryBot.define do
  factory :netex_import, class: Import::Netex, parent: :import do
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
    association :parent, factory: :workbench_import
  end
end
