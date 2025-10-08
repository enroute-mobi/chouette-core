# frozen_string_literal: true

FactoryBot.define do
  factory :netex_generic_export, class: Export::NetexGeneric, parent: :export do
    type {'Export::NetexGeneric'}
    association :referential, factory: :workbench_referential
    setup do
      {
        scope_setup: {
          type: 'Export::Setup::Scope::Referential',
          vehicle_journeys: {
            period: {
              type: 'Export::Setup::Scope::PeriodSelector::Duration',
              day_count: 60
            }
          }
        },
        profile: 'european'
      }
    end
  end
end
