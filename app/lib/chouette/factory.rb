# coding: utf-8
module Chouette
  class Factory
    extend Definition

    define do
      model :organisation do
        attribute(:name) { |n| "Organisation #{n}" }
        attribute(:code) { |n| "000#{n}" }

        model :user do
          attribute(:name) { |n| "chouette#{n}" }
          attribute(:username) { |n| "chouette#{n}" }
          attribute(:email) { |n| "chouette+#{n}@enroute.mobi" }
          attribute :password, "secret"
          attribute :password_confirmation, "secret"
        end
      end

      model :workgroup do
        attribute(:name) { |n| "Workgroup ##{n}" }
        attribute(:owner) { build_model :organisation }

        model :line_referential, required: true, singleton: true do
          attribute(:name) { |n| "Line Referential #{n}" }
          attribute :objectid_format, 'netex'

          after do |line_referential|
            owner = line_referential.workgroup.owner
            line_referential.add_member owner, owner: true
          end

          model :line do
            attribute(:name) { |n| "Line #{n}" }
            attribute :transport_mode, "bus"
            attribute :transport_submode, "undefined"
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

        model :stop_area_referential, required: true, singleton: true do
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
              line = line_referential.lines.create!(name: "Line #{sequence_number}", transport_mode: "bus", transport_submode: "undefined", number: sequence_number)
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
                line_ids: transient(:lines, resolve_instances: true).map(&:id),
                periodes: transient(:periods)
              }
              new_instance.metadatas.build metadata_attributes
            end

            around_models do |referential, block|
              referential.save! if referential.new_record?
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
                attribute(:published_name) { |n| "Public Name #{n}" }

                after do |journey_pattern|
                  journey_pattern.stop_points = journey_pattern.route.stop_points
                end

                model :vehicle_journey do
                  attribute(:published_journey_name) { |n| "Vehicle Journey #{n}" }

                  after do |vehicle_journey|
                    # TODO move this in the VehicleJourney model
                    vehicle_journey.route = vehicle_journey.journey_pattern.route
                  end

                  transient :with_stops, true
                  transient :departure_time, '12:00:00'

                  after do
                    first_departure_time = Time.parse(transient(:departure_time))

                    parent.stop_points.each_with_index do |stop_point, index|
                      arrival_time = first_departure_time + index * 5.minute
                      departure_time = arrival_time + 1.minute

                      attributes = {
                        stop_point: stop_point,
                        arrival_time: "2000-01-01 #{arrival_time.strftime("%H:%M:%S")} UTC",
                        departure_time: "2000-01-01 #{departure_time.strftime("%H:%M:%S")} UTC"
                      }

                      new_instance.vehicle_journey_at_stops.build attributes
                    end if transient(:with_stops)
                  end
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

              after do
                Array(transient(:dates_included)).each do |date|
                  new_instance.dates.build in_out: true, date: date
                end
                Array(transient(:dates_excluded)).each do |date|
                  new_instance.dates.build in_out: false, date: date
                end
                Array(transient(:periods)).each do |period|
                  new_instance.periods.build period_start: period.min, period_end: period.max
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

    def self.create(options = {}, &block)
      new.tap do |factory|
        factory.evaluate(&block)
      end
    end

    def initialize
      @root_context = Context.new(self.class.root)
    end

    def instance(name)
      root_context.named_instances[name]
    end

    def evaluate(options = {}, &block)
      root_context.evaluate(&block)
      root_context.debug if options[:debug]
      root_context.create_instance
    end

    attr_reader :root_context

  end
end
