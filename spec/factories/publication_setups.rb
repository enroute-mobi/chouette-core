FactoryBot.define do
  factory :publication_setup do
    sequence(:name) { |n| "Publication #{n}" }
    workgroup { create(:workgroup) }
    enabled {false}

    export_options { {type: "Export::Gtfs", duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }
  end

  factory :publication_setup_gtfs, :parent => :publication_setup do
    export_options { {type: "Export::Gtfs", duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }
  end

  factory :publication_setup_netex_generic, :parent => :publication_setup do
    export_options { { type: "Export::NetexGeneric", duration: 200, profile: :none } }
  end
end
