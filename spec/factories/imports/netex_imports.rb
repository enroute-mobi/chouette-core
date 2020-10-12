FactoryBot.define do
  factory :netex_import, class: Import::Netex, parent: :import do
    file { File.open(Rails.root.join('spec', 'fixtures', 'OFFRE_TRANSDEV_2017030112251.zip')) }
    association :parent, factory: :workbench_import
  end
end
