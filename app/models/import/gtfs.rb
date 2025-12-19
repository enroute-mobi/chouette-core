# frozen_string_literal: true

class Import::Gtfs < Import::Base
  include LocalImportSupport
  include Measurable

  after_commit :update_main_resource_status, on:  [:create, :update]

  def operation_progress_weight(operation_name)
    operation_name.to_sym == :stop_times ? 90 : 10.0/10
  end

  def operations_progress_total_weight
    100
  end

  def self.accepts_file?(file)
    Zip::File.open(file) do |zip_file|
      agency_file = File.join('**', 'agency.txt')
      zip_file.glob(agency_file).size == 1
    end
  rescue => e
    Chouette::Safe.capture "Error in testing GTFS file: #{file}", e
    return false
  end

  def lines
    line_referential.lines.by_provider(line_provider)
  end

  def companies
    line_referential.companies.by_provider(line_provider)
  end

  def booking_arrangements
    line_referential.booking_arrangements.by_provider(line_provider)
  end

  def referential_metadata
    registration_numbers = source.routes.map(&:id)
    line_ids = lines.where(registration_number: registration_numbers).pluck(:id)

    ReferentialMetadata.new line_ids: line_ids, periodes: [source.validity_period]
  end

  def source
    @source ||= ::GTFS::Source.build local_file.path, strict: false
  end

  def prepare_referential
    import_resources :agencies, :stops, :routes, :shapes, :transfers, :fare_products, :fare_validities, :booking_arrangements, :location_groups

    create_referential
    referential.switch
  end

  def import_without_status
    prepare_referential

    check_calendar_files_missing_and_create_message || import_resources(:services)

    RouteJourneyPatterns.new(self).import!

    import_resources :stop_times

    import_resources :attributions

    # TODO: why the resource statuses are not checked automaticaly ??
    # See CHOUETTE-2747
    resource_status = resources.map(&:status).uniq
    Rails.logger.debug "resource_status: #{resource_status.inspect}"
    if resource_status.include?(:ERROR)
      @status ||= 'failed'
    elsif resource_status.include?(:WARNING)
      @status ||= 'warning'
    end
  end

  # For (ugly) tests purpose
  def import_route_and_journey_patterns
    RouteJourneyPatterns.new(self).import!
  end

  def import_attributions
    Attributions.new(self).import!
  end

  class Part < Import::Part
    delegate :source, :lookup, :create_message, :workbench, :referential, :referential_inserter, :save_model, to: :import
  end

  def referential_lookup
    @referential_lookup ||= Import::Lookup.referential(self)
  end

  def trip_lookup
    @trip_lookup ||= TripLookup.new(referential:, lookup: referential_lookup, shape_provider:, code_space:)
  end

  class Attributions < Part
    def import!
      source.attributions.each do |attribution|
        decorator = Decorator.for(attribution)&.new(
                                                   attribution,
                                                   referential: referential,
                                                   code_space: code_space,
                                                   workbench: workbench,
                                                   lookup: lookup
                                                 )

        decorator.attribute! if decorator
      end
    end

    class Decorator < SimpleDelegator

      def initialize(attribution, referential: nil, code_space: nil, workbench: nil, lookup: nil)
        super attribution
        @referential = referential
        @code_space = code_space
        @workbench = workbench
        @lookup = lookup
      end
      attr_accessor :referential, :code_space, :workbench, :lookup

      def self.for(gtfs_attribution)
        [TripOperatorDecorator, ContractDecorator].find do |decorator_class|
          decorator_class.matches?(gtfs_attribution)
        end
      end

      def companies
        @companies ||= workbench.companies.includes(:codes).where(name: organization_name)
      end

      def company
        @company ||= companies.first unless companies.many?
      end
    end

    class TripOperatorDecorator < Decorator
      def self.matches?(gtfs_attribution)
        gtfs_attribution.operator? && gtfs_attribution.trip_id && gtfs_attribution.organization_name
      end

      def vehicle_journey
        # TODO: should be managed by Lookup
        referential.vehicle_journeys.by_code(code_space, trip_id).first
      end

      def attribute!
        return if vehicle_journey.blank? || company.blank?

        vehicle_journey.update company: company
      end
    end

    class ContractDecorator < Decorator
      def self.matches?(gtfs_attribution)
        gtfs_attribution.producer? && !gtfs_attribution.trip_id &&
          gtfs_attribution.organization_name && !gtfs_attribution.operator? &&
          gtfs_attribution.route_id && !gtfs_attribution.authority?
      end

      def contract
        @contract ||= company.contracts.first_or_initialize_by_code(code_space, code_value) do |contract|
          contract.name = organization_name
          contract.workbench = workbench
        end if company
      end

      def line
        lookup.lines.find(route_id)
      end

      def code_value
        company.registration_number || company.objectid
      end

      def attribute!
        return unless contract && line

        contract.update line_ids: [contract.line_ids, line.id].flatten.compact.uniq
      end
    end
  end

  class BookingArrangements < Part
    delegate :booking_arrangements, to: :import

    def import!
      source.booking_rules.each do |booking_rule|
        decorated_booking_arrangement = Decorator.new(booking_rule)

        unless decorated_booking_arrangement.valid?
          decorated_booking_arrangement.errors.each { |error| create_message error }
          next
        end

        booking_arrangements.first_or_initialize_by_code(code_space, decorated_booking_arrangement.id) do |booking_arrangement|
          booking_arrangement.attributes = decorated_booking_arrangement.booking_arrangement_attributes

          save_model booking_arrangement
        end
      end
    end

    class Decorator < SimpleDelegator
      def book_when
        case booking_type
        when '0'
          :time_of_travel_only
        when '1'
          :advance_and_day_of_travel
        when '2'
          :until_previous_day
        end
      end

      def booking_arrangement_attributes
        {
          name: "GTFS Booking Rule #{id}",
          book_when: book_when,
          minimum_booking_period: prior_notice_duration_min,
          latest_booking_time: prior_notice_last_time,
          booking_notes: message,
          phone: phone_number,
          url: info_url,
          booking_url: booking_url
        }
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        unless booking_type.in? %w{0 1 2}
          errors << {
            criticity: :error,
            message_key: 'gtfs.booking_arrangements.invalid_booking_type'
          }
        end

        if booking_type == '1' && prior_notice_duration_min.blank?
          errors << {
            criticity: :error,
            message_key: 'gtfs.booking_arrangements.missing_prior_notice_duration_min'
          }
        end

        if prior_notice_last_day.present? && prior_notice_last_time.blank?
          errors << {
            criticity: :error,
            message_key: 'gtfs.booking_arrangements.missing_prior_notice_last_time'
          }
        end

        errors.empty?
      end
    end
  end

  def import_booking_arrangements
    resource = create_resource(:booking_rules)
    resource.rows_count = source.booking_rules.count
    resource.save!

    BookingArrangements.new(WithResource.new(self, resource)).import!
    resource.update_status_from_messages
  end

  class LocationGroups < Part
    delegate :stop_areas, to: :import

    def import!
      source.location_groups.each do |location_group|
        decorated_location_group = Decorator.new(location_group, lookup.stop_areas)

        unless decorated_location_group.valid?
          decorated_location_group.errors.each { |error| create_message error }
          next
        end

        stop_area = stop_areas.find_or_initialize_by(registration_number: decorated_location_group.id)

        if stop_area.persisted? && stop_area.area_type.to_sym != Chouette::AreaType::FLEXIBLE_STOP_PLACE
          create_message(
            criticity: :error,
            message_key: 'gtfs.location_groups.area_type_is_not_flexible_stop_place',
            message_attributes: {
              stop_area_name: stop_area.name,
              registration_number: stop_area.registration_number,
              area_type: stop_area.area_type
            }
          )
          next
        end

        stop_area.attributes = decorated_location_group.stop_area_attributes

        save_model stop_area
      end
    end

    class Decorator < SimpleDelegator
      def initialize(location_group, stop_areas)
        super location_group

        @stop_areas = stop_areas
      end
      attr_reader :stop_areas

      def stop_area_attributes
        {
          name: name,
          flexible_area_memberships_attributes: flexible_area_memberships_attributes,
          area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE
        }
      end

      def flexible_area_memberships_attributes
        @flexible_area_memberships_attributes ||= [].tap do |flexible_area_memberships_attributes|
          stops.each do |stop|
            if member_id = stop_areas.find_id(stop.stop_id)
              flexible_area_memberships_attributes << { member_id: member_id }
            else
              missing_member_ids << stop.stop_id
            end
          end
        end
      end

      def missing_member_ids
        @missing_member_ids ||= []
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        # Compute attributes before
        stop_area_attributes

        if missing_member_ids.any?
          errors << {
            criticity: :error,
            message_key: 'gtfs.location_groups.missing_member_ids',
            message_attributes: {
              missing_member_ids: missing_member_ids.join(', ')
            }
          }
        end

        errors.empty?
      end
    end
  end

  def import_location_groups
    resource = create_resource(:location_groups)
    resource.rows_count = source.location_groups.count
    resource.save!

    LocationGroups.new(WithResource.new(self, resource)).import!
    resource.update_status_from_messages
  end


  def import_agencies
    resource = create_resource(:agencies)
    resource.rows_count = source.agencies.count
    resource.save!

    Agencies.new(WithResource.new(self, resource)).import!
    resource.update_status_from_messages
  end

  # Try to hide the resource management for modern code
  #
  # Provides #save_model and #create_message method without resource concept/argument
  class WithResource < SimpleDelegator

    def initialize(import, resource)
      super import

      @import, @resource = import, resource
    end

    attr_reader :import, :resource

    def save_model(model)
      import.save_model model, resource: resource
    end

    def create_message(attributes_or_error)
      attributes =
        if attributes_or_error.is_a?(Import::Decorator::Error)
          error = attributes_or_error

          gtfs_resource = error.resource
          resource_collection = gtfs_resource.class.name.demodulize.tableize

          {
            criticity: (error.criticity || :error),
            message_key: "gtfs.#{resource_collection}.#{error.message_key}",
            message_attributes: error.message_attributes,
            resource_attributes: {
              filename: gtfs_resource.filename,
              line_number: gtfs_resource.line_number
            }
          }
        else
          attributes_or_error[:resource_attributes] = {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count
          }
          attributes_or_error
        end

      import.create_message attributes, resource: resource, commit: true
    end

  end

  def specific_default_company
    return nil unless parent_option('specific_default_company_id').present?

    @specific_default_company ||= parent.candidate_companies.find_by(id: parent_options['specific_default_company_id'])
  end

  class Agencies < Part
    attr_reader :import
    delegate :companies, :specific_default_company,
             :default_company=, :default_time_zone, :default_time_zone=, to: :import

    def import!
      if specific_default_company
        self.default_company = specific_default_company

        if specific_default_company&.time_zone
          self.default_time_zone = ActiveSupport::TimeZone[specific_default_company.time_zone]
        end

        return
      end

      source.agencies.each do |agency|
        decorated_agency = Decorator.new(agency, default_time_zone: default_time_zone, mandatory_id: !default_agency?)

        unless decorated_agency.valid?
          decorated_agency.errors.each { |error| create_message error }
          next
        end

        # TODO use code
        company = companies.find_or_initialize_by registration_number: decorated_agency.code
        company.attributes = decorated_agency.company_attributes

        save_model company

        self.default_company = company if default_agency?
        self.default_time_zone = decorated_agency.time_zone # TODO Company should support real TimeZone object ..
      end
    end

    def default_agency?
      @default_agency ||= source.agencies.one?
    end

    class Decorator < SimpleDelegator

      def initialize(agency, default_time_zone: nil, mandatory_id: false)
        super agency
        @agency, @default_time_zone, @mandatory_id = agency, default_time_zone, mandatory_id
      end

      attr_reader :agency
      attr_accessor :default_time_zone, :mandatory_id
      alias mandatory_id? mandatory_id

      def code
        id.presence || default_code
      end

      def default_code
        name.presence && name.parameterize
      end

      def time_zone
        @time_zone ||= ActiveSupport::TimeZone[timezone] if timezone
      end

      def time_zone_name
        time_zone.tzinfo.name if time_zone
      end

      def company_attributes
        {
          name: name,
          default_language: lang,
          default_contact_url: url,
          default_contact_phone: phone,
          fare_url: fare_url,
          time_zone: time_zone_name # TODO Company should support real TimeZone object ..
        }
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        if mandatory_id? && id.blank?
          errors << {
            criticity: :error,
            message_key: 'gtfs.agencies.missing_agency_id'
          }
        end

        unless time_zone
          errors << {
            criticity: :error,
            message_key: :invalid_time_zone,
            message_attributes: {
              time_zone: timezone,
            }
          }
        end

        if default_time_zone && time_zone != default_time_zone
          errors << {
            criticity: :error,
            message_key: 'gtfs.agencies.default_time_zone'
          }
        end

        errors.empty?
      end

    end

  end

  attr_accessor :default_time_zone, :default_company

  class StopAreaZone
    def initialize(zone_id: nil, code_space: nil, fare_provider: nil, stop_area_id: nil)
      @zone_id = zone_id
      @code_space = code_space
      @fare_provider = fare_provider
      @stop_area_id = stop_area_id
    end

    attr_reader :zone_id, :code_space, :fare_provider, :stop_area_id

    def zone
      return unless zone_id.present?

      @zone ||= fare_provider.fare_zones.first_or_create_by_code(code_space, zone_id) do |zone|
        zone.name = zone_id
      end
    end

    def import!
      return unless zone

      zone.stop_area_zones.find_or_create_by(stop_area_id: stop_area_id)
    end
  end

  def store_imported_stop_area_registration_number(stop_area)
    (@store_imported_stop_area_registration_number ||= []) << stop_area.registration_number
  end

  def import_stops
    sorted_stops = source.stops.sort_by { |s| s.parent_station.present? ? 1 : 0 }

    create_resource(:stops).each(sorted_stops, slice: 100, transaction: true) do |stop, resource|
      next if ignore_parent_stop_areas? && stop.location_type == '1'

      stop_area = stop_areas.find_or_initialize_by(registration_number: stop.id)
      expected_area_type = stop.location_type == '1' ? 'zdlp' : 'zdep'

      if stop_area.new_record?
        stop_area.area_type = expected_area_type
      else
        if stop_area.area_type != expected_area_type
          create_message(
            {
              criticity: :error,
              message_key: 'gtfs.stops.invalid_location_type',
              message_attributes: {
                location_type: stop.location_type,
                stop_area_name: stop_area.name,
                stop_area_type: Chouette::AreaType.find(stop_area.area_type).label,
                registration_number: stop_area.registration_number
              },
              resource_attributes: {
                filename: "#{resource.name}.txt",
                line_number: resource.rows_count,
                column_number: 0
              }
            },
            resource: resource, commit: true
          )

          next
        end
      end

      stop_area.name = stop.name
      stop_area.public_code = stop.platform_code
      stop_area.stop_area_provider = stop_area_provider
      stop_area.latitude = stop.lat.presence && stop.lat.to_f
      stop_area.longitude = stop.lon.presence && stop.lon.to_f
      stop_area.kind = :commercial
      stop_area.deleted_at = nil
      stop_area.confirmed_at ||= Time.now
      stop_area.comment = stop.desc

      if stop.wheelchair_boarding.present?
        case stop.wheelchair_boarding
        when '0'
          stop_area.wheelchair_accessibility = 'unknown'
        when '1'
          stop_area.wheelchair_accessibility = 'yes'
        when '2'
          stop_area.wheelchair_accessibility = 'no'
        end
      end

      stop_area.codes.find_or_initialize_by(code_space: public_code_space).tap do |code|
        code.value = stop.code
        code.save unless stop_area.new_record?
      end if stop.code.present?

      if stop.parent_station.present? && !ignore_parent_stop_areas?
        if check_parent_is_valid_or_create_message(Chouette::StopArea, stop.parent_station, resource)
          parent = find_stop_parent_or_create_message(stop.name, stop.parent_station, resource)
          if parent
            stop_area.parent = parent
            stop_area.time_zone = parent.time_zone if parent.time_zone
          end
        end
      end

      if stop.timezone.present?
        time_zone = ActiveSupport::TimeZone[stop.timezone]
        if time_zone
          stop_area.time_zone = time_zone.tzinfo.name
        else
          create_message(
            {
              criticity: :error,
              message_key: :invalid_time_zone,
              message_attributes: {
                time_zone: stop.timezone,
              },
              resource_attributes: {
                filename: "#{resource.name}.txt",
                line_number: resource.rows_count,
                column_number: 0
              }
            },
            resource: resource, commit: true
          )
        end
      else
        stop_area.time_zone = default_time_zone&.tzinfo&.name # TODO StopArea should support real TimeZone object ..
      end

      save_model stop_area, resource: resource
      store_imported_stop_area_registration_number(stop_area)

      StopAreaZone.new(
        zone_id: stop.zone_id,
        code_space: code_space,
        fare_provider: fare_provider,
        stop_area_id: stop_area.id
      ).import!
    end

    if disable_missing_resources?
      unknown_stop_areas =
        stop_area_provider.stop_areas.where.not(registration_number: @store_imported_stop_area_registration_number)
      unknown_stop_areas.update_all deleted_at: Time.current
    end
  end
  measure :import_stops, as: :stops

  def lines_by_registration_number(registration_number)
    @lines_by_registration_number ||= {}
    line = lines.includes(:company).find_or_initialize_by(registration_number: registration_number)
    line.line_provider = line_provider
    @lines_by_registration_number[registration_number] ||= line
  end

  def transport_modes
    @transport_modes ||= {
      0 => 'tram',
      1 => 'metro',
      2 => 'rail',
      3 => 'bus',
      4 => 'water',
      5 => 'funicular/streetCableCar',
      6 => 'telecabin',
      7 => 'funicular',
      11 => 'trolleyBus',
      12 => 'rail/monorail',
      100 => 'rail',
      103 => 'rail/interregionalRail',
      200 => 'coach',
      204 => 'coach/regionalCoach',
      205 => 'coach/specialCoach',
      208 => 'coach/commuterCoach',
      700 => 'bus',
      702 => 'bus/expressBus',
      705 => 'bus/nightBus',
      711 => 'bus/shuttleBus',
      713 => 'bus/schoolAndPublicServiceBus',
      714 => 'bus/railReplacementBus',
      715 => 'bus/demandAndResponseBus'
    }.transform_keys(&:to_s).transform_values { |definition| Chouette::TransportMode.from(definition) }
  end

  def import_routes
    @lines_by_registration_number = {}

    create_resource(:routes).each(source.routes, transaction: true) do |route, resource|
      if route.agency_id.present?
        next unless check_parent_is_valid_or_create_message(Chouette::Company, route.agency_id, resource)
      end
      line = lines_by_registration_number(route.id)

      if line_name = route.long_name.presence || route.short_name.presence
        line.name = line_name
      end

      if line_number = route.short_name.presence
        line.number = line_number
      end

      if line_published_name = route.long_name.presence
        line.published_name = line_published_name
      end

      if route.agency_id.blank?
        line.company = default_company if default_company
      else
        line.company_id = lookup.companies.find_id(route.agency_id)
      end

      if line_comment = route.desc.presence
        line.comment = line_comment
      end

      if transport_mode = transport_modes[route.type]
        line.chouette_transport_mode = transport_mode
      end

      # White is the default color in the gtfs spec
      line.color = parse_color(route.color) if route.color
      # Black is the default text color in the gtfs spec
      line.text_color = parse_color(route.text_color) if route.text_color

      line.url = route.url if route.url.presence

      save_model line, resource: resource
    end

    if disable_missing_resources?
      unknown_lines = line_provider.lines.where.not(registration_number: @lines_by_registration_number.keys)
      unknown_lines.update_all deactivated: true
    end
  end
  measure :import_routes, as: :routes

  def import_transfers
    with_warning_lookup = lookup.on_response(on: :stop_areas) do |response, arguments|
      if response.source == :workgroup
        resource = arguments[:resource]
        code = response.code

        create_message(
          {
            criticity: :warning,
            message_key: 'gtfs.transfers.stop_id_from_stop_area_referential',
            message_attributes: { stop_id: code },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
      end
    end

    create_resource(:transfers).each(source.transfers, slice: 100, transaction: true) do |transfer, resource|
      next unless transfer.type == '2'
      from_id = with_warning_lookup.stop_areas.find_id(transfer.from_stop_id, resource: resource)
      unless from_id
        create_message(
          {
            criticity: :error,
            message_key: 'gtfs.transfers.missing_stop_id',
            message_attributes: { stop_id: transfer.from_stop_id },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end
      to_id = with_warning_lookup.stop_areas.find_id(transfer.to_stop_id, resource: resource)
      unless to_id
        create_message(
          {
            criticity: :error,
            message_key: 'gtfs.transfers.missing_stop_id',
            message_attributes: { stop_id: transfer.to_stop_id },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end
      if from_id == to_id
        create_message(
          {
            criticity: :warning,
            message_key: 'gtfs.transfers.same_arrival_and_departure',
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end

      connection = connection_links.find_by(departure_id: from_id, arrival_id: to_id, both_ways: true)
      connection ||= connection_links.find_or_initialize_by(departure_id: to_id, arrival_id: from_id, both_ways: true)
      if transfer.min_transfer_time.present?
        connection.default_duration = transfer.min_transfer_time
        if [:frequent_traveller_duration, :occasional_traveller_duration,
            :mobility_restricted_traveller_duration].any? { |k| connection.send(k).present? }
          create_message(
            {
              criticity: :warning,
              message_key: 'gtfs.transfers.replacing_duration',
              message_attributes: { from_id: transfer.from_stop_id, to_id: transfer.to_stop_id },
              resource_attributes: {
                filename: "#{resource.name}.txt",
                line_number: resource.rows_count,
                column_number: 0
              }
            },
            resource: resource,
            commit: true
          )
        end
      end
      save_model connection, resource: resource
    end
  end
  measure :import_transfers, as: :transfers

  def referential_inserter
    @referential_inserter ||= ReferentialInserter.new(referential) do |config|
      config.add IdInserter
      config.add TimestampsInserter
      config.add CopyInserter
    end
  end

  # Import Routes and JourneyPatterns according to GTFS Trips
  class RouteJourneyPatterns < Part
    delegate :trip_lookup, to: :import

    def route_inserter
      @route_inserter ||= Import::RouteInserter.new(
        referential_inserter, on_save: on_save, on_invalid: on_invalid
      )
    end

    def on_save
      ->(model)  {
        if model.is_a?(Chouette::JourneyPattern)
          register_journey_pattern model
          improve_shape model
        end
      }
    end

    def on_invalid
      lambda do |model|
        Rails.logger.info { "Invalid Model: #{model.inspect} #{model.errors.inspect}" }
      end
    end

    def register_journey_pattern(journey_pattern)
      trip_lookup.journey_patterns.register journey_pattern, signature: journey_pattern.transient(:signature)
    end

    def improved_shape_ids
      @improved_shape_ids ||= Set.new
    end

    def improve_shape(journey_pattern)
      return unless journey_pattern.shape_id
      return unless improved_shape_ids.add?(journey_pattern.shape_id)

      shape = journey_pattern.shape
      return unless shape

      shape.name = journey_pattern.name if shape.name.blank?
      shape.waypoints = journey_pattern.waypoints unless shape.waypoints.any?
      shape.save
    end

    def import!
      route_decorators.each do |route_decorator|
        # TODO: retrieve RouteDecorator errors ?
        # To replace code like that :-/
        #
        # unless_parent_model_in_error(Chouette::StopArea, stop_time.stop_id, resource) do
        #   if position == 0
        #     departure_time = GtfsTime.parse(stop_time.departure_time)
        #     raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?
        #   end

        #   stop_area_id = @stop_areas_id_by_registration_number[stop_time.stop_id]
        #   raise InvalidStopAreaError unless stop_area_id.present?
        # end

        route_inserter.insert route_decorator.route
      end

      referential_inserter.flush
    end

    # Regroups GTFS Trips by Journey Pattern signature
    # Each group will become a Journey Pattern
    def journey_pattern_descriptions
      decorators = {}

      source.trips(with_stop_times: true).each do |trip|
        decorator = TripDecorator.new(trip)
        next unless decorator.journey_pattern_signature

        decorators[decorator.journey_pattern_signature] ||= decorator
      end

      decorators.values
    end

    # Cluster candidate Journey Patterns to find Route candidates
    def route_clusters
      journey_pattern_descriptions.group_by(&:route_signature).values.flat_map do |journey_pattern_descriptions|
        RouteCluster.compute(journey_pattern_descriptions)
      end
    end

    # Regroups information to create Route and associated Journey Patterns
    def route_decorators
      route_clusters.map do |route_cluster|
        RouteDecorator.new(
          route_cluster.stop_sequence,
          route_cluster.children,
          lookup: lookup
        )
      end
    end

    class RouteCluster

      def initialize(stop_sequence, children = [])
        @stop_sequence = stop_sequence
        @children = children
      end

      attr_reader :stop_sequence, :children

      def include?(candidate_sequence)
        candidate_enumerator = Nest::NonFiberEnumerator.new(candidate_sequence)
        candidate_stop = candidate_enumerator.next

        stop_sequence.each do |stop|
          if stop == candidate_stop
            candidate_stop = candidate_enumerator.next
          end
        end

        false
      rescue StopIteration
        true
      end

      def ==(other)
        stop_sequence == other.stop_sequence && children == other.children
      end

      def inspect
        description = "#<RouteCluster #{stop_sequence.inspect}"
        description += " children=#{children.inspect}" if children.present?
        description += ">"
      end

      def add(stop_sequence)
        children << stop_sequence
        self
      end
      alias << add

      def self.compute(stop_sequences)
        stop_sequences = stop_sequences.sort_by { |s| -s.length }

        clusters = []

        stop_sequences.each do |stop_sequence|
          candidate = clusters.find { |c| c.include?(stop_sequence) }

          if candidate
            candidate << stop_sequence
          else
            clusters << RouteCluster.new(stop_sequence).add(stop_sequence)
          end
        end

        clusters
      end
    end

    class RouteDecorator < SimpleDelegator
      def initialize(route_description, journey_pattern_descriptions, lookup: nil)
        super route_description
        @journey_pattern_descriptions = journey_pattern_descriptions

        # Used to retrieve model identifiers for associated resources
        @lookup = lookup
      end

      attr_reader :journey_pattern_descriptions, :lookup
      delegate :stop_areas, :lines, :shapes, to: :lookup

      def route
        Chouette::Route.new(route_attributes)
      end

      def route_attributes
        {
          line_id: line_id,
          name: name,
          wayback: wayback,
          stop_points: stop_points,
          journey_patterns: journey_patterns
        }
      end

      def line_id
        lines.find_id route_id
      end

      def wayback
        direction_id == '0' ? :outbound : :inbound
      end

      def name
        headsign.presence || wayback.to_s.capitalize
      end

      def stop_points
        @stop_points ||= stop_times.map.with_index do |stop_time, position|
          gtfs_stop_id = stop_time.stop_id.presence || stop_time.location_group_id
          stop_area_id = stop_areas.find_id(gtfs_stop_id)

          Chouette::StopPoint.new(
            stop_area_id: stop_area_id,
            position: position,
            for_boarding: convert_pickup_and_drop_off_type(stop_time.pickup_type, flexible?(stop_time)),
            for_alighting: convert_pickup_and_drop_off_type(stop_time.drop_off_type, flexible?(stop_time)),
            flexible: flexible?(stop_time),
          ).with_transient(stop_id: stop_time.stop_id)
        end
      end

      def journey_patterns
        journey_pattern_decorators.map(&:journey_pattern)
      end

      def journey_pattern_decorators
        journey_pattern_descriptions.map do |journey_pattern_description|
          JourneyPatternDecorator.new self, journey_pattern_description
        end
      end

      private

      def flexible?(stop_time)
        stop_time.start_pickup_drop_off_window.present? || stop_time.end_pickup_drop_off_window.present?
      end

      def convert_pickup_and_drop_off_type(value, is_flexible)
        if is_flexible
          # A flexible GTFS Stop Time should use drop_off/pickup type 2
          value == '2' ? 'normal' : 'forbidden'
        else
          # A standard GTFS Stop Time is 'normal' excepted if type 1 is used
          value == '1' ? 'forbidden' : 'normal'
        end
      end
    end

    class JourneyPatternDecorator < SimpleDelegator
      def initialize(route_decorator, journey_pattern_description)
        super journey_pattern_description
        @route_decorator = route_decorator
      end

      attr_reader :route_decorator
      delegate :name, :shapes, to: :route_decorator

      def journey_pattern
        Chouette::JourneyPattern.new(journey_pattern_attributes).with_transient(signature: journey_pattern_signature)
      end

      def journey_pattern_attributes
        {
          name: name,
          published_name: published_name,
          journey_pattern_stop_points: journey_pattern_stop_points,
          shape_id: chouette_shape_id
        }
      end

      def published_name
        headsign
      end

      def journey_pattern_stop_points
        # WARNING
        # looking for StopPoint using only stop_id would create bugs when a Loop is present
        stop_point_enumerator = Nest::NonFiberEnumerator.new(route_decorator.stop_points)

        stop_ids.map do |stop_id|
          next_route_stop_point = stop_point_enumerator.next
          until stop_id == next_route_stop_point.transient(:stop_id)
            next_route_stop_point = stop_point_enumerator.next
          end

          Chouette::JourneyPatternStopPoint.new stop_point: next_route_stop_point
        end
      end

      def chouette_shape_id
        shapes.find_id shape_id
      end
    end
  end

  # DEPRECATED: Use Trips part
  def import_stop_times
    resource = create_resource(:stop_times)
    resource.rows_count = source.stop_times.count
    resource.save!

    Trips.new(WithResource.new(self, resource)).import!

    resource.update_status_from_messages
  end

  class Trips < Part
    delegate :default_time_zone, to: :import

    def lookup
      import.trip_lookup
    end

    def import!
      source.trips(with_stop_times: true).each do |trip|
        decorator = TripDecorator.new(trip, lookup: lookup, code_space: code_space, default_time_zone: default_time_zone)
        unless decorator.valid?
          decorator.errors.each { |error| create_message error }
          next
        end

        vehicle_journey_inserter.insert decorator.chouette_model
      end

      referential_inserter.flush
    end

    def vehicle_journey_inserter
      @vehicle_journey_inserter ||= Import::VehicleJourneyInserter.new(referential_inserter, on_invalid: on_invalid)
    end

    def on_invalid
      lambda do |model|
        Rails.logger.warn { "Invalid Model: #{model.errors.inspect}" }
        # TODO ensure a message is created
        create_message(
          criticity: :error,
          message_key: 'gtfs.trips.invalid_vehicle_journey',
          message_attributes: { trip_id: model.published_journey_identifier }
        )
      end
    end
  end

  def find_stop_parent_or_create_message(stop_area_name, parent_station, resource)
    # Ugly, but this code should be into a dedicated Part :-/
    @with_warning_parent_lookup ||= lookup.on_response(on: :stop_areas) do |response, arguments|
      if response.source == :workgroup
        resource = arguments[:resource]
        code = response.code

        create_message(
          {
            criticity: :warning,
            message_key: :stop_area_parent_in_workgroup,
            message_attributes: {
              parent: code,
              # TODO: We should use the registration number to identify Stop Areas in message
              stop_area: stop_area_name
            }
          },
          resource: resource, commit: true
        )
      end
    end

    parent = @with_warning_parent_lookup.stop_areas.find(parent_station, resource: resource)

    unless parent
      create_message(
        {
          criticity: :error,
          message_key: :parent_not_found,
          message_attributes: {
            parent_name: parent_station,
            stop_area_name: stop_area_name
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
    end
    parent
  end

  def check_calendar_files_missing_and_create_message
    if source.entries.include?('calendar.txt') || source.entries.include?('calendar_dates.txt')
      return false
    end

    create_message(
      {
        criticity: :error,
        message_key: 'missing_calendar_or_calendar_dates_in_zip_file',
      },
      resource: resource, commit: true
    )
    @status = 'failed'
  end

  def parse_color(value)
    /\A[\dA-F]{6}\Z/.match(value.upcase).try(:string)
  end

  def shape_referential
    workgroup.shape_referential
  end

  def shape_provider
    workbench.default_shape_provider
  end

  def fare_provider
    workbench.default_fare_provider
  end

  delegate :stop_areas, to: :stop_area_provider
  delegate :connection_links, to: :stop_area_provider

  def index
    @index ||= Index.new
  end

  class Index
    def initialize
      @fare_ids = {}
    end

    def register_fare_id(fare_product, fare_id)
      @fare_ids[fare_product.id] = fare_id
    end

    def fare_product_ids
      @fare_ids.keys
    end
  end

  def import_shapes
    resource = create_resource(:shapes)
    resource.rows_count = source.shapes.count
    resource.save!

    Shapes.new(WithResource.new(self, resource)).import!

    resource.update_status_from_messages
  end

  class Shapes < Part
    delegate :shape_provider, to: :import

    def import!
      source.shapes.each_slice(1000).each do |gtfs_shapes|
        Shape.transaction do
          gtfs_shapes.each do |gtfs_shape|
            decorator = Decorator.new(gtfs_shape, code_space: code_space)

            unless decorator.valid?
              decorator.errors.each { |error| create_message error }
              next
            end

            shape = collection.by_code(code_space, decorator.code_value).first_or_initialize
            shape.attributes = decorator.shape_attributes
            shape.save!
          end
        end
      end
    end

    def collection
      shape_provider.shapes
    end

    class Decorator < SimpleDelegator
      mattr_accessor :maximum_point_count, default: 10_000

      mattr_reader :factory, default: RGeo::Geos.factory(srid: 4326)

      def initialize(shape, code_space: nil)
        super shape

        @code_space = code_space
      end

      attr_accessor :code_space

      def code_value
        id
      end

      def code
        Code.new(code_space: code_space, value: code_value) if code_space
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        if points.count > maximum_point_count || points.count < 2
          errors << {
            criticity: :error,
            message_key: :unreasonable_shape,
            message_attributes: { shape_id: id }
          }
        end

        errors.empty?
      end

      def rgeos_points
        points.map do |point|
          factory.point point.longitude, point.latitude
        end
      end

      def rgeos_geometry
        factory.line_string rgeos_points
      end

      def shape_attributes
        {
          geometry: rgeos_geometry,
          codes: [ code ]
        }
      end
    end

  end

  def import_fare_products
    resource = create_resource(:fare_attributes)
    resource.rows_count = source.fare_attributes.count
    resource.save!

    FareProducts.new(self).import!

    resource.update_status_from_messages
  end

  class FareProducts < Part
    delegate :fare_provider, :index, :default_company, to: :import

    def import!
      source.fare_attributes.each do |fare_atribute|
        decorator = Decorator.new(fare_atribute, code_space: code_space, companies: lookup.companies,
                                  default_company: default_company, fare_provider: fare_provider)

        product = decorator.build_or_update
        unless product.save
          Rails.logger.warn "Can't save Fare Product #{product.inspect}"
          next
        end

        index.register_fare_id product, decorator.code_value
      end
    end

    class Decorator < SimpleDelegator
      def initialize(fare_attribute, code_space: nil, companies: nil, default_company: nil, fare_provider: nil)
        super fare_attribute

        @code_space = code_space
        @companies = companies
        @fare_provider = fare_provider
        @default_company = default_company
      end

      attr_accessor :code_space, :companies, :fare_provider, :default_company

      def build_or_update
        return unless fare_provider

        fare_provider.fare_products.first_or_initialize_by_code(code_space, code_value).tap do |product|
          product.attributes = attributes
        end
      end

      def code_value
        fare_id
      end

      def name
        fare_id
      end

      def price_cents
        (price.to_f * 100).round
      end

      def company
        if agency_id.blank?
          default_company
        else
          companies&.find(agency_id)
        end
      end

      def attributes
        # Managed: fare_id, price, agency_id
        # Ignored: currency_type, payment_method, transfers, transfer_duration

        {
          name: name,
          price_cents: price_cents,
          company: company
        }
      end
    end
  end

  def import_fare_validities
    resource = create_resource(:fare_rules)
    resource.rows_count = source.fare_rules.count
    resource.save!

    FareValidities.new(self).import!

    resource.update_status_from_messages
  end

  class FareValidities < Part
    delegate :fare_provider, :index, to: :import

    def import!
      source.fare_rules.each do |fare_rule|
        decorator = Decorator.new(fare_rule, code_space: code_space, fare_provider: fare_provider, lines: lookup.lines)

        validity = decorator.build_or_update
        unless validity.save
          Rails.logger.warn "Can't save Fare Validity #{validity.inspect}"
          next
        end

        fare_validity_ids << validity.id
      end

      clean_fare_validities
    end

    def fare_validity_ids
      @fare_validity_ids ||= []
    end

    def clean_fare_validities
      imported_products = fare_provider.fare_products.where(id: index.fare_product_ids)
      not_imported_fare_validities = fare_provider.fare_validities.where.not(id: fare_validity_ids)

      not_imported_fare_validities.by_products(imported_products).destroy_all
    end

    class Decorator < SimpleDelegator
      def initialize(fare_rule, code_space: nil, lines: nil, fare_provider: nil)
        super fare_rule

        @code_space = code_space
        @lines = lines
        @fare_provider = fare_provider
      end

      attr_accessor :code_space, :lines, :fare_provider

      delegate :fare_validities, :fare_products, :fare_zones, to: :fare_provider, allow_nil: true

      def build_or_update
        return unless fare_validities

        fare_validities.first_or_initialize_by_code(code_space, code_value).tap do |validity|
          validity.attributes = attributes
        end
      end

      def code_value
        # GTFS Fare Rules have no id
        # The primary key is defined as "*" ...

        "#{fare_id}-#{route_id}-#{origin_id}-#{destination_id}-#{contains_id}"
      end

      def attributes
        {
          name: name,
          products: [product],
          expression: expression
        }
      end

      def name
        NameBuilder.new(self).name
      end

      # Create a Validity name like "C2 - Zones A > D - Zone B"
      class NameBuilder
        def initialize(decorator)
          @decorator = decorator
        end

        attr_accessor :decorator

        delegate :line, :origin_zone, :destination_zone, :contains_zone, to: :decorator

        def name
          [
            line_name,
            zone_to_zone_name,
            zone_name
          ].compact.join(' - ')
        end

        def line_name
          line&.name
        end

        def zone_to_zone_name
          return unless origin_zone || destination_zone

          parts = ['Zones', origin_zone&.name, '>', destination_zone&.name]
          parts.compact.join(' ')
        end

        def zone_name
          "Zone #{contains_zone&.name}" if contains_zone
        end
      end

      def product
        return unless fare_products && fare_id.present?

        fare_products.by_code(code_space, fare_id).first
      end

      def line
        lines&.find(route_id)
      end

      def find_or_create_zone(zone_id)
        return unless fare_zones && zone_id.present?

        fare_zones.first_or_create_by_code(code_space, zone_id) do |zone|
          zone.name = zone_id
        end
      end

      def origin_zone
        find_or_create_zone(origin_id)
      end

      def destination_zone
        find_or_create_zone(destination_id)
      end

      def contains_zone
        find_or_create_zone(contains_id)
      end

      def line_expression
        Fare::Validity::Expression::Line.new(line: line) if line
      end

      def zone_to_zone_expression
        return unless origin_zone || destination_zone

        Fare::Validity::Expression::ZoneToZone.new(from: origin_zone, to: destination_zone)
      end

      def zone_expression
        Fare::Validity::Expression::Zone.new(zone: contains_zone) if contains_zone
      end

      def expressions
        @expressions ||= [line_expression, zone_to_zone_expression, zone_expression].compact
      end

      def expression
        if expressions.many?
          Fare::Validity::Expression::Composite.new(expressions: expressions)
        else
          expressions.first
        end
      end
    end
  end

  class Decorator < Import::Decorator
    # TODO: Could share more code
  end

  def import_services
    resource = create_resource(:services)
    # TODO: any performance impact ?
    resource.rows_count = source.services.count
    resource.save!

    Services.new(WithResource.new(self, resource)).import!

    resource.update_status_from_messages
    # TODO: why the import status must be changed manually ?!
    @status = 'failed' if resource.status == :ERROR
  end

  class Services < Part
    def import!
      # Retrieve both calendar and associated calendar_dates into a single GTFS::Service model
      source.services.each do |service|
        decorator = Decorator.new(service, code_space: code_space)

        # Decorator can have errors but provides a TimeTable
        decorator.errors.each { |error| import.create_message error } unless decorator.valid?

        time_table = decorator.time_table
        next unless time_table&.valid?

        # TODO: use inserter
        time_table.save!
      end
    end

    class Decorator < Import::Gtfs::Decorator
      attr_accessor :index

      # Returns a Cuckoo::Timetable::DaysOfWeek according to GTFS Service monday?/.../sunday?
      def days_of_week
        Cuckoo::Timetable::DaysOfWeek.new.tap do |days_of_week|
          %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
            days_of_week.enable day if send "#{day}?"
          end
        end
      end

      # Returns a Period according to GTFS Service date_range
      def period
        Period.for_range date_range if date_range
      end

      def included_dates
        calendar_dates.select(&:included?).map(&:ruby_date).compact
      end

      def excluded_dates
        calendar_dates.select(&:excluded?).map(&:ruby_date).compact
      end

      def memory_timetable_period
        Cuckoo::Timetable::Period.from(period, days_of_week) if period
      end

      def memory_timetable
        @memory_timetable ||= Cuckoo::Timetable.new(
          period: memory_timetable_period,
          included_dates: included_dates,
          excluded_dates: excluded_dates
        ).normalize!
      end

      def name
        service_id
      end

      def codes_attributes
        [
          {
            code_space_id: code_space&.id,
            value: service_id
          }
        ]
      end

      delegate :empty?, to: :memory_timetable

      def time_table
        return nil if name.blank?

        @time_table ||= Chouette::TimeTable.new(comment: name, codes_attributes: codes_attributes).apply(memory_timetable)
      end

      def validate
        super

        errors.add :service_without_id if service_id.blank?
        # TODO: Unused code ?
        # if index&.service_id?(service_id)
        #   errors.add :duplicated_service_id, message_attributes: { service_id: service_id }
        # end
        if memory_timetable.empty?
          errors.add :empty_service, message_attributes: { service_id: service_id }, criticity: :warning
        end
        if !time_table&.valid?
          errors.add :invalid_service, message_attributes: { service_id: service_id }
        end
      end
    end
  end
end
