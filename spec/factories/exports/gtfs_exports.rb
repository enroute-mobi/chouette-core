FactoryBot.define do
  factory :gtfs_export, class: Export::Gtfs, parent: :export do
    options {{duration: 90, prefer_referent_stop_area: false, ignore_single_stop_station: false}}
    type {'Export::Gtfs'}
    file { File.open(Rails.root.join('spec', 'fixtures', 'OFFRE_TRANSDEV_2017030112251.zip')) }
    association :parent, factory: :workgroup_export
    association :referential, factory: :workbench_referential
  end
end
