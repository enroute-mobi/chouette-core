# coding: utf-8
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
            owner = line_referential.workgroup.owner
            line_referential.add_member owner, owner: true
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
          attribute :objectid_format, 'netex'

          after do |stop_area_referential|
            owner = stop_area_referential.workgroup.owner
            stop_area_referential.add_member owner, owner: true
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

        model :workbench do
          attribute(:name) { |n| "Workbench #{n}" }
          attribute(:organisation) { build_model :organisation }
          attribute :objectid_format, "netex"
          attribute(:prefix) { |n| "prefix-#{n}" }

          after do
            # TODO shouldn't be explicit but managed by Workbench model
            new_instance.stop_area_referential = parent.stop_area_referential
            new_instance.line_referential = parent.line_referential

            new_instance.stop_area_referential.add_member new_instance.organisation
            new_instance.line_referential.add_member new_instance.organisation
          end

          model :referential do
            attribute(:name) { |n| "Referential #{n}" }

            transient(:lines) do
              # TODO create a Line with Factory::Model ?
              line_referential = parent.workgroup.line_referential
              line = line_referential.lines.create(name: "Line #{sequence_number}", transport_mode: "bus", number: sequence_number)
              [ line ]
            end
            transient :periods, [ Date.today.beginning_of_year..Date.today.end_of_year ]

            after do
              # TODO shouldn't be explicit but managed by Workbench/Referential model
              new_instance.stop_area_referential = parent.stop_area_referential
              new_instance.line_referential = parent.line_referential
              new_instance.prefix = parent.respond_to?(:prefix) ? parent.prefix : "chouette"
              new_instance.organisation = parent.organisation

              metadata_attributes = {
                line_ids: transient(:lines).map(&:id),
                periodes: transient(:periods)
              }
              new_instance.metadatas.build metadata_attributes
            end

            around_models do |referential, block|
              referential.save!
              referential.switch { block.call }
            end

            model :route do
              attribute(:name) { |n| "Route #{n}" }
              attribute(:published_name) { |n| "Published Route Name #{n}" }

              attribute(:line) { parent.metadatas_lines.first }

              model :stop_point, count: 3, required: true do
                attribute(:stop_area) do
                  # TODO create a StopArea with Factory::Model ?
                  stop_area_referential = parent.referential.stop_area_referential

                  attributes = {
                    name: "Stop Area #{sequence_number}",
                    kind: "commercial",
                    area_type: "zdep",
                    latitude: 48.8584 - 5 + 10 * rand,
                    longitude: 2.2945 - 2 + 4 * rand
                  }

                  stop_area_referential.stop_areas.create! attributes
                end
              end
              model :journey_pattern do
                attribute(:name) { |n| "JourneyPattern #{n}" }

                after do |journey_pattern|
                  journey_pattern.stop_points = journey_pattern.route.stop_points
                end

                model :vehicle_journey do
                  attribute(:published_journey_name) { |n| "Vehicle Journey #{n}" }

                  after do |vehicle_journey|
                    # TODO move this in the VehicleJourney model
                    vehicle_journey.route = vehicle_journey.journey_pattern.route
                  end

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
    end

    def self.create(&block)
      context = Context.new(root)
      context.evaluate &block
      context.create_instance
    end

  end
end
