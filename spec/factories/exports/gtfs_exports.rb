FactoryBot.define do
  factory :gtfs_export, class: Export::Gtfs, parent: :export do
    options {{duration: 90, prefer_referent_stop_area: false}}
    type {'Export::Gtfs'}
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
    association :referential, factory: :workbench_referential
  end
end
