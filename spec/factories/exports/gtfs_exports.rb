# frozen_string_literal: true

FactoryBot.define do
  factory :gtfs_export, class: Export::Gtfs, parent: :export do
    type {'Export::Gtfs'}
    association :referential, factory: :workbench_referential
    setup do
      {
        scope_setup: {
          type: 'Export::Setup::Scope::Referential',
          stop_areas: {
            prefer_referent_stop_areas: false
          },
          vehicle_journeys: {
            period: {
              type: 'Export::Setup::Scope::PeriodSelector::Duration',
              day_count: 90
            }
          }
        }
      }
    end
    file { file_fixture('OFFRE_TRANSDEV_2017030112251.zip').open }
  end
end
