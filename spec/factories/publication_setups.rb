FactoryGirl.define do
  factory :publication_setup do
    sequence(:name) { |n| "Publication #{n}" }
    workgroup { create(:workgroup) }
    enabled false
    export_type "Export::Gtfs"
    export_options { { duration: 200 } }
  end

  factory :publication_setup_gtfs, :parent => :publication_setup do |u|
    export_type "Export::Gtfs"
    export_options { { duration: 200 } }
  end

  factory :publication_setup_idfm_netex_full, :parent => :publication_setup do |u|
    export_type "Export::Netex"
    export_options { {export_type: :full, duration: 60} }
  end

  factory :publication_setup_idfm_netex_line, :parent => :publication_setup do |u|
    export_type "Export::Netex"
    export_options { {export_type: :line, duration: 60} }
  end

  factory :publication_setup_netex_full, :parent => :publication_setup do |u|
    export_type "Export::NetexFull"
    export_options { { duration: 200 } }
  end

end
