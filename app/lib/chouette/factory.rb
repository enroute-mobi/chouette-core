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

          # FIXED User#permissions should be [] by default
          attribute(:permissions) { [] }
        end
      end

      model :workgroup do
        attribute(:name) { |n| "Workgroup #{n}" }
        attribute(:owner) { build_root_model :organisation }
        attribute(:export_types) { Workgroup::DEFAULT_EXPORT_TYPES }

        model :line_referential, required: true, singleton: true do
          attribute(:name) { |n| "Line Referential #{n}" }
          attribute :objectid_format, 'netex'

          after do |line_referential|
            owner = line_referential.workgroup.owner
            line_referential.add_member owner, owner: true
          end
        end

        model :stop_area_referential, required: true, singleton: true do
          attribute(:name) { |n| "StopArea Referential #{n}" }
          attribute :objectid_format, 'netex'

          after do |stop_area_referential|
            owner = stop_area_referential.workgroup.owner
            stop_area_referential.add_member owner, owner: true
          end
        end

        model :shape_referential, required: true, singleton: true do

        end

        model :code_space do
          attribute(:short_name) { |n| "code_space_#{n}" }
        end

        model :workbench do
          attribute(:name) { |n| "Workbench #{n}" }
          attribute(:organisation) { build_root_model :organisation }
          attribute :objectid_format, "netex"
          attribute(:prefix) { |n| "prefix-#{n}" }

          after do
            # TODO shouldn't be explicit but managed by Workbench model
            new_instance.stop_area_referential = parent.stop_area_referential
            new_instance.line_referential = parent.line_referential

            new_instance.stop_area_referential.add_member new_instance.organisation
            new_instance.line_referential.add_member new_instance.organisation
          end

          model :notification_rule do
            attribute(:period) { Range.new(Time.zone.today, Time.zone.today + 10.days) }
            attribute(:priority) { 10 }
            attribute(:notification_type) { 'hole_sentinel' }
            attribute(:target_type) { 'workbench' }
            attribute(:operation_statuses) { [] }
            attribute(:line_ids) { [] }
          end

          model :compliance_check_set do
            attribute(:name) { |n| "Test #{n}" }
            after do
              new_instance.workgroup = parent.workgroup
            end
          end

          model :line_provider do
            attribute(:short_name) { |n| "line_provider_#{n}" }

            model :line do
              attribute(:name) { |n| "Line #{n}" }
              attribute :transport_mode, "bus"
              attribute :transport_submode, "undefined"
              attribute(:number) { |n| n }

              transient :codes

              after do
                (transient(:codes) || {}).each do |code_space_short_name, value|
                  code_space = new_instance.workgroup.code_spaces.find_by!(short_name: code_space_short_name)
                  new_instance.codes.build(code_space: code_space, value: value)
                end
              end
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

            model :line_notice do
              transient :lines

              attribute(:title) { |n| "Line Notice title #{n}" }
              attribute(:content) { |n| "Line Notice content #{n}" }
              attribute(:objectid) { |n| "organisation:LineNotice:#{n}:LOC" }

              after do
                lines = Array(transient(:lines))
                lines.each { |line| line.line_notices << new_instance }
              end
            end
          end

          model :stop_area_provider do
            attribute(:name) { |n| "Stop Area Provider #{n}" }
            after do
              new_instance.stop_area_referential = parent.stop_area_referential
            end

            model :stop_area do
              attribute(:name) { |n| "Stop Area #{n}" }
              attribute :kind, "commercial"
              attribute :area_type, "zdep"

              attribute(:latitude) { 48.8584 - 5 + 10 * rand }
              attribute(:longitude) { 2.2945 - 2 + 4 * rand }

              transient :codes

              after do
                new_instance.stop_area_referential = parent.stop_area_referential

                (transient(:codes) || {}).each do |code_space_short_name, value|
                  code_space = new_instance.workgroup.code_spaces.find_by!(short_name: code_space_short_name)
                  new_instance.codes.build(code_space: code_space, value: value)
                end
              end

              model :entrance do
                attribute(:name) { |n| "Entrance #{n}" }
                after do
                  new_instance.stop_area_provider = parent.stop_area_provider
                end
              end
            end
          end

          model :shape_provider do
            attribute(:short_name) { |n| "shape_provider_#{n}" }

            model :shape do
              attribute(:name) { |n| "Shape #{n}" }
              attribute(:geometry) { |n| "LINESTRING(48.8584 2.2945,48.859 2.295)" }
            end

          end

          model :referential do
            attribute(:name) { |n| "Referential #{n}" }

            transient(:lines) do
              # TODO create a Line with Factory::Model ?
              line = parent.default_line_provider.lines.create!(name: "Line #{sequence_number}", transport_mode: "bus", transport_submode: "undefined", number: sequence_number)
              [ line ]
            end
            transient :periods, [ Time.zone.today..1.month.from_now.to_date ]

            transient :with_metadatas, true

            after do
              # TODO shouldn't be explicit but managed by Workbench/Referential model
              new_instance.stop_area_referential = parent.stop_area_referential
              new_instance.line_referential = parent.line_referential
              new_instance.prefix = parent.respond_to?(:prefix) ? parent.prefix : "chouette"
              new_instance.organisation = parent.organisation
              new_instance.ready = true

              if transient(:with_metadatas)
                metadata_attributes = {
                  line_ids: transient(:lines, resolve_instances: true).map(&:id),
                  periodes: transient(:periods)
                }
                new_instance.metadatas.build metadata_attributes
              end
            end

            around_models do |referential, block|
              referential.save! if referential.new_record?
              referential.switch { block.call }
            end

            model :route do
              attribute(:name) { |n| "Route #{n}" }
              attribute(:published_name) { |n| "Published Route Name #{n}" }

              attribute(:line) { parent.metadatas_lines.first }

              transient :with_stops, true
              transient :stop_count, 3

              # Can be used to specify a stop area list to create stop points
              transient :stop_areas

              model :stop_point do
                attribute(:stop_area) do
                  # TODO create a StopArea with Factory::Model ?
                  stop_area_referential = parent.referential.stop_area_referential

                  attributes = {
                    name: "Stop Area #{sequence_number}",
                    kind: "commercial",
                    area_type: "zdep",
                    latitude: 48.8584 - 5 + 10 * rand,
                    longitude: 2.2945 - 2 + 4 * rand,
                    stop_area_referential: stop_area_referential
                  }
                  default_stop_area_provider = parent.referential.workbench.default_stop_area_provider
                  default_stop_area_provider.save! if default_stop_area_provider.new_record?
                  default_stop_area_provider.stop_areas.create! attributes
                end
              end

              after do |route|
                (transient(:stop_areas, resolve_instances: true) || []).each do |stop_area|
                  stop_point = build_model(:stop_point)
                  stop_point.stop_area = stop_area

                  route.stop_points << stop_point
                end

                transient(:stop_count).times do
                  route.stop_points << build_model(:stop_point)
                end if transient(:stop_areas).blank? && transient(:with_stops)
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
                  transient :time_tables, []

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

                    transient(:time_tables, resolve_instances: true).each do |time_table|
                      new_instance.time_tables << time_table
                    end
                  end
                end
              end
              model :routing_constraint_zone do
                attribute(:name) { |n| "Routing Constraint Zone #{n}" }

                after do |routing_constraint_zone|
                  routing_constraint_zone.stop_points = routing_constraint_zone.route.stop_points.last(2)
                end
              end
            end

            model :footnote do
              attribute(:code) { |n| "FootNote #{n}" }
              attribute(:label) { |n| "FootNote Label #{n}" }
            end

            model :time_table do
              transient :dates_included, []
              transient :dates_excluded, []
              transient :periods, [ Time.zone.today..1.month.from_now.to_date ]

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
          end
        end
      end
    end

    def self.create(options = {}, &block)
      new.tap do |factory|
        factory.evaluate(options, &block)
      end
    end

    def initialize
      @root_context = Context.new(self.class.root)
    end

    def instance(name)
      root_context.registry.find name: name
    end

    def method_missing(method_name, *arguments)
      instances = root_context.registry.dynamic_model_method(method_name, *arguments)
      if instances.present?
        return instances
      end

      super
    end

    def evaluate(options = {}, &block)
      root_context.evaluate(&block)
      root_context.debug
      root_context.create_instance
    end

    attr_reader :root_context

    class Error < StandardError; end

  end
end
