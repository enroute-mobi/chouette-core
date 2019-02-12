FactoryGirl.define do

  factory :line, :class => Chouette::Line do
    sequence(:name) { |n| "Line #{n}" }
    sequence(:published_name) { |n| "Line-#{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:Line:#{n}" }
    sequence(:number, 1)


    association :network, :factory => :network
    association :company, :factory => :company

    transport_mode "bus"

    before(:create) do |line|
      line.line_referential ||= LineReferential.find_by! name: "first"
    end

    sequence(:registration_number) { |n| "test-#{n}" }

    url { Faker::Internet.url }

    transient do
      referential nil
    end

    after(:create) do |line, evaluator|
      if evaluator.referential && evaluator.referential.workbench
        organisation = evaluator.referential.workbench.organisation
        organisation.sso_attributes ||= {}
        functional_scope = organisation.sso_attributes['functional_scope'] || "[]"
        functional_scope = JSON.parse functional_scope
        functional_scope << line.objectid
        organisation.sso_attributes['functional_scope'] = functional_scope.to_json
        organisation.save
      end
    end

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
              comm = create(:stop_area, :area_type => "gdl")
              stop_point.stop_area.update_attributes(:parent_id => comm.id)
            end
          end
        end
      end

    end

    factory :line_with_after_commit do |line|
      line.run_callbacks(:commit)

    end

  end

end
