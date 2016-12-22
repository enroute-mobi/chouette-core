FactoryGirl.define do

  factory :line, :class => Chouette::Line do
    sequence(:name) { |n| "Line #{n}" }
    sequence(:objectid) { |n| "chouette:test:Line:#{n}" }
    sequence(:transport_mode) { |n| "bus" }

    association :network, :factory => :network
    association :company, :factory => :company

    before(:create) do |line|
      line.line_referential ||= LineReferential.find_by! name: "first"
    end

    sequence(:registration_number) { |n| "test-#{n}" }

    factory :line_with_stop_areas do

      transient do
        routes_count 2
        stop_areas_count 5
      end

      after(:create) do |line, evaluator|
        create_list(:route, evaluator.routes_count, :line => line) do |route|
          create_list(:stop_area, evaluator.stop_areas_count, area_type: "zdep") do |stop_area|
            create(:stop_point, :stop_area => stop_area, :route => route)
          end
        end
      end

      factory :line_with_stop_areas_having_parent do

        after(:create) do |line|
          line.routes.each do |route|
            route.stop_points.each do |stop_point|
              comm = create(:stop_area, :area_type => "lda")
              stop_point.stop_area.update_attributes(:parent_id => comm.id)
            end
          end
        end
      end

    end

  end

end
