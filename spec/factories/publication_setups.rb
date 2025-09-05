FactoryBot.define do
  factory :publication_setup do
    sequence(:name) { |n| "Publication #{n}" }
    workgroup { create(:workgroup) }
    enabled {false}
    export_setup do
      {
        type: 'Export::Setup::Gtfs',
        scope_setup: {
          type: 'Export::Setup::Scope::PublishedReferential'
        }
      }
    end
  end

  factory :publication_setup_gtfs, :parent => :publication_setup

  factory :publication_setup_netex_generic, :parent => :publication_setup do
    export_setup do
      {
        type: 'Export::Setup::Netex',
        scope_setup: {
          type: 'Export::Setup::Scope::PublishedReferential'
        }
      }
    end
  end
end
