FactoryGirl.define do
  factory :gtfs_import, class: Import::Gtfs, parent: :import do
    file { File.open(Rails.root.join('spec', 'fixtures', 'OFFRE_TRANSDEV_2017030112251.zip')) }
    association :parent, factory: :workbench_import

  end
end
