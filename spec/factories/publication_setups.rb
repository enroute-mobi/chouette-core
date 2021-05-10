FactoryBot.define do
  factory :publication_setup do
    sequence(:name) { |n| "Publication #{n}" }
    workgroup { create(:workgroup) }
    enabled {false}
    transient do
      export_type { "Export::Gtfs" }
    end

    export_options { {type: "Export::Gtfs", duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }

    after(:build) do |ps, evaluator|
      ps.export_options[:type] = evaluator.export_type
    end
  end

  factory :publication_setup_gtfs, :parent => :publication_setup do
    export_options { {type: "Export::Gtfs", duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false } }

    transient do
      export_type { "Export::Gtfs" }
    end
  end

  factory :publication_setup_netex_generic, :parent => :publication_setup do
    export_options { { type: "Export::NetexGeneric", duration: 200, profile: :none } }

    transient do
      export_type { "Export::NetexGeneric" }
    end
  end

  factory :publication_setup_idfm_netex_full, :parent => :publication_setup do
    export_options { { type:  "Export::Netex", export_type: :full, duration: 60} }

    transient do
      export_type { "Export::Netex" }
    end
  end
end
