module Chouette
  module Factory
    extend Definition

    define do
      model :organisation do
        attribute(:name) { |n| "Organisation #{n}" }
        attribute(:code) { |n| "000#{n}" }

        model :user do
          attribute(:name) { |n| "chouette#{n}" }
          attribute(:username) { |n| "chouette#{n}" }
          attribute(:email) { |n| "chouette+#{n}@af83.com" }
          attribute :password, "secret"
          attribute :password_confirmation, "secret"
        end
      end

      model :workgroup do
        attribute(:name) { |n| "Workgroup ##{n}" }
        attribute(:owner) { build_model :organisation }

        model :line_referential, required: true do
          attribute(:name) { |n| "Line Referential #{n}" }
          attribute :objectid_format, 'netex'

          after do |line_referential|
            line_referential.add_member line_referential.workgroup.owner
          end

          model :line do
            attribute(:name) { |n| "Line #{n}" }
            attribute :transport_mode, "bus"
            attribute(:number) { |n| n }
          end

          model :company do
            attribute(:name) { |n| "Company #{n}" }
          end

          model :network do
            attribute(:name) { |n| "Network #{n}" }
          end

          model :group_of_line do
            attribute(:name) { |n| "Group of Line #{n}" }
          end
        end

        model :stop_area_referential, required: true do
          attribute(:name) { |n| "StopArea Referential #{n}" }
          attribute :objectid_format, 'reflex'

          after do |stop_area_referential|
            stop_area_referential.add_member stop_area_referential.workgroup.owner
          end

          model :stop_area do
            attribute(:name) { |n| "Stop Area #{n}" }
            attribute :kind, "commercial"
            attribute :area_type, "zdep"

            attribute(:latitude) { 48.8584 - 5 + 10 * rand }
            attribute(:longitude) { 2.2945 - 2 + 4 * rand }
          end

          model :stop_area_provider do
            attribute(:name) { |n| "Stop Area Provider #{n}" }
          end
        end


        model :referential do
          transient(:lines) { build_model(:line) }
          transient :periods, [ Date.today.beginning_of_year..Date.today.end_of_year ]

          model :route do
            attribute(:line) { parent.metadata_lines.first }

            model :stop_point, count: 3, required: true do
              attribute(:stop_area) { build_model :stop_area }
            end
            model :journey_pattern do
              after do |journey_pattern|
                journey_pattern.stop_points = journey_pattern.route.stop_points
              end

              model :vehicle_journey do
                attribute(:name) { |n| "Journey Pattern #{n}" }
                attribute(:published_name) { |n| "Journey Pattern Published Name #{n}" }

                # TODO vehicle_journey_at_stop
              end
            end
            model :routing_constraint_zone do
              attribute(:name) { |n| "Routing Constraint Zone #{n}" }

              after do |routing_constraint_zone|
                routing_constraint_zone.stop_points = routing_constraint_zone.route.stop_points.last(2)
              end
            end
            model :footnote do
              attribute(:code) { |n| "FootNote #{n}" }
              attribute(:label) { |n| "FootNote Label #{n}" }
            end
          end

          model :time_table do
            transient :dates_included, []
            transient :dates_excluded, []
            transient :periods, [ Date.today.beginning_of_year..Date.today.end_of_year ]

            attribute(:comment) { |n| "TimeTable #{n}" }
            attribute :int_day_types, TimeTable::EVERYDAY

            after do |time_table|
              transient(:dates_included).each do
                # TODO
              end
              transient(:dates_excluded).each do
                # TODO
              end
              transient(:periods).each do
                # TODO
              end
            end
          end
          model :purchase_window do
            attribute(:name) { |n| "Purchase Window #{n}" }
            attribute :date_ranges, [ Date.today.beginning_of_year..Date.today.end_of_year ]
          end
        end
      end
    end

    HIERARCHY = {
      organisation: [:user],

      workgroup: {
        line_referential: %i{line company network group_of_line},
        stop_area_referential: {
          stop_area: [:access_point],
          stop_area_provider: []
        },
        referential: {
          route: {
            stop_point: [],
            journey_pattern: {
              vehicle_journey: []
            },
            routing_constraint_zone: [],
            footnote: []
          },
          time_table: [],
          purchase_window: []
        }
      }
    }.freeze

    def self.create(&block)
      context = Context.new(root)
      context.evaluate &block
      context.build
      context.save
    end

  end
end
