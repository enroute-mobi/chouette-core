class Export::NetexGeneric < Export::Base
  include LocalExportSupport

  option :profile, enumerize: %w[none french european idfm/iboo idfm/icar idfm/full], default: :none
  option :duration
  option :from, serialize: ActiveModel::Type::Date
  option :to, serialize: ActiveModel::Type::Date
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :period, default_value: 'all_periods', enumerize: %w[all_periods only_next_days static_day_period]
  option :exported_lines, default_value: 'all_line_ids', enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :participant_ref, default_value: 'enRoute'
  option :profile_options, default_value: {}, serialize: ActiveRecord::Type::Json
  option :prefer_referent_line, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :exported_code_space

  validate :ensure_is_valid_period

  def ensure_is_valid_period
    return unless period == 'static_day_period'

    if from.blank? || to.blank? || from > to
      errors.add(:from, :invalid)
      errors.add(:to, :invalid)
    end
  end

  def target
    @target ||= Netex::Target.build(export_file,
                                    profile: netex_profile,
                                    publication_timestamp: Time.zone.now,
                                    participant_ref: participant_ref,
                                    validity_periods: [export_scope.validity_period],
                                    profile_options: profile_options)
  end
  attr_writer :target

  def profile?
    ! [nil, 'none'].include? profile
  end

  def netex_profile
    @netex_profile ||= Netex::Profile.create(profile) if profile?
  end

  def content_type
    profile? ? 'application/zip' : 'text/xml'
  end

  def file_extension
    profile? ? "zip" : 'xml'
  end

  delegate :stop_area_referential, :line_referential, to: :workgroup

  class Scope < SimpleDelegator
    def initialize(export_scope, export:)
      super export_scope

      @export = export
    end

    attr_reader :export
    delegate :stop_area_referential, :line_referential, to: :export

    def current_scope
      __getobj__
    end

    def stop_areas
      @stop_areas ||=
        ::Query::StopArea.new(stop_area_referential.stop_areas).
          self_referents_and_ancestors(current_scope.stop_areas)
    end

    def entrances
      # Must unscope the entrances to find entrances associated with all exported Stop Areas
      # (including parent Stop Areas)
      stop_area_referential.entrances.where(stop_area: stop_areas)
    end

    def lines_class
      prefer_referent_lines? ? Lines::PreferReferents : Lines::Default
    end

    def lines
      @lines ||= lines_class.new(self).lines
      #  prefer_referent_lines? ? lines_or_referents : lines_and_referents
    end

    module Lines
      class Base
        def initialize(export_scope)
          @export_scope = export_scope
        end

        attr_reader :export_scope
        delegate :line_referential, :current_scope, to: :export_scope

        def all_lines
          line_referential.lines
        end

        def original_scoped_lines
          current_scope.lines
        end
      end

      class Default < Base
        def lines_and_referents
          ::Query::Line.new(all_lines).self_and_referents(original_scoped_lines)
        end

        alias lines lines_and_referents
      end

      class PreferReferents < Base
        def lines_or_referents
          line_referential.lines.where(id: lines_or_referent_ids)
        end

        alias lines lines_or_referents

        def lines_or_referent_ids
          [
            original_scoped_lines.without_referent,
            all_lines.where(id: original_scoped_lines.with_referent.select(:referent_id))
          ].flat_map { |relation| relation.pluck(:id) }.uniq
        end
      end
    end

    def prefer_referent_lines?
      export.prefer_referent_line
    end

    def referenced_lines
      if prefer_referent_lines?
        current_scope.lines.particulars.with_referent
      else
        Chouette::Line.none
      end
    end
  end

  def export_scope
    @local_export_scope ||= Scope.new(super, export: self)
  end

  def resource_tagger
    @resource_tagger ||= ResourceTagger.new(code_provider: code_provider)
  end

  def export_file
    @export_file ||= Tempfile.new(["export#{id}",'.zip'])
  end

  def generate_export_file
    part_classes = [
      Entrances,
      Quays,
      StopPlaces,
      Companies,
      Networks,
      Lines,
      # Export StopPoints before Routes to detect local references
      StopPoints,
      Routes,
      RoutingConstraintZones,
      JourneyPatterns,
      TimeTables,
      VehicleJourneyAtStops,
      VehicleJourneys,
      VehicleJourneyStopAssignments,
      Organisations,
      PointOfInterests
    ]

    part_classes.each_with_index do |part_class, index|
      part_class.new(self).export_part
    end

    target.close
    export_file.close

    export_file
  end

  class TaggedTarget
    def initialize(target, tags = {})
      @target = target
      @tags = tags
    end

    def add(resource)
      resource.tags = @tags
      @target << resource
    end
    alias << add
  end

  class Part
    attr_reader :export

    def initialize(export, options = {})
      @export = export
      options.each { |k,v| send "#{k}=", v }
    end

    delegate :target, :resource_tagger, :export_scope, :workgroup,
             :alternate_identifiers_extractor, :code_provider, to: :export

    def part_name
      @part_name ||= self.class.name.demodulize.underscore
    end

    def export_part
      Chouette::Benchmark.measure part_name do
        export!
      end
    end

    def decorate(model, **attributes)
      decorator_class = attributes.delete(:with) || default_decorator_class

      attributes = attributes.merge(
        alternate_identifiers_extractor: alternate_identifiers_extractor,
        code_provider: code_provider
      )
      decorator_class.new model, **attributes
    end

    def default_decorator_class
      @decorator_class ||= self.class.const_get('Decorator')
    end
  end

  class ResourceTagger
    def initialize(code_provider: nil)
      @code_provider = code_provider
    end

    def code_provider
      @code_provider ||= Export::CodeProvider.null
    end

    # Returns tags for several lines.
    # Returns only uniq values accross all given lines
    def tags_for_lines line_ids
      tags = Hash.new { |h,k| h[k] = Set.new }

      line_ids.each do |line_id|
        tags_for(line_id).each do |key, value|
          tags[key] << value
        end
      end

      # Remove multiple values
      tags.map do |key, set|
        [ key, set.first ] if set.size == 1
      end.compact.to_h
    end

    def tags_for line_id
      tag_index[line_id]
    end

    def register_tag_for(line)
      tag_index[line.id] = {
        line_id: code_provider.lines.code(line.id),
        line_name: line.name,
        operator_id: code_provider.companies.code(line.company_id),
        operator_name: line.company&.name
      }.compact
    end

    protected

    def tag_index
      @tag_index ||= Hash.new { |h,k| h[k] = {} }
    end
  end

  def alternate_identifiers_extractor
    @alternate_identifiers_extractor ||= AlternateIdentifiersExtractor.new(workgroup&.code_spaces || [])
  end

  class AlternateIdentifiersExtractor
    def initialize(code_spaces)
      @code_spaces = code_spaces.map do |code_space|
        [ code_space.id, code_space.short_name ]
      end.to_h
    end

    attr_reader :code_spaces

    def decorate(model)
      Decorator.new(model, code_spaces: code_spaces)
    end

    class Decorator
      def initialize(model, code_spaces: {})
        @model = model
        @code_spaces = code_spaces
      end
      attr_reader :model, :code_spaces

      delegate :registration_number, :codes, to: :model

      def registration_number_value
        if has_registration_number?
          [[ "external", registration_number ]]
        else
          []
        end
      end

      def has_registration_number?
        model.respond_to?(:registration_number) && registration_number.present?
      end

      def has_codes?
        model.respond_to? :codes
      end

      def codes_values
        if has_codes?
          codes.map do |code|
            code_space_short_name = code_spaces[code.code_space_id]
            [ code_space_short_name, code.value ] if code_space_short_name
          end.compact
        else
          []
        end
      end

      def alternate_identifiers_values
        registration_number_value + codes_values
      end

      def alternate_identifiers
        alternate_identifiers_values.map do |key, value|
          Netex::KeyValue.new key: key, value: value, type_of_key: "ALTERNATE_IDENTIFIER"
        end
      end
    end
  end

  class CustomFieldExtractor

    def initialize(model)
      @model = model
    end
    attr_reader :model

    delegate :custom_field_values, to: :model, allow_nil: true

    def custom_field_identifiers
      return [] unless custom_field_values.present?

      custom_field_values.map do |key, value|
        Netex::KeyValue.new key: key, value: value, type_of_key: "chouette::custom-field"
      end
    end

  end

  module Accessibility
    def accessibility_assessment
      return unless accessibility_assessment?

      Netex::AccessibilityAssessment.new(
        id: netex_identifier&.change(type: 'AccessibilityAssessment').to_s,
        mobility_impaired_access: netex_value(mobility_impaired_accessibility),
        limitations: [accessibility_limitation].compact,
        validity_conditions: [availability_condition].compact
      )
    end

    def accessibility_limitation
      return unless accessibility_limitation?

      Netex::AccessibilityLimitation.new(
        wheelchair_access: netex_value(wheelchair_accessibility),
        step_free_access: netex_value(step_free_accessibility),
        escalator_free_access: netex_value(escalator_free_accessibility),
        lift_free_access: netex_value(lift_free_accessibility),
        audible_signals_available: netex_value(audible_signals_availability),
        visual_signs_available: netex_value(visual_signs_availability)
      )
    end

    def netex_value(value)
      case value
      when 'yes'
        'true'
      when 'no'
        'false'
      else
        value
      end
    end

    def availability_condition
      return unless accessibility_limitation_description.present?

      Netex::AvailabilityCondition.new(
        id: netex_identifier.change(type: 'AvailabilityCondition').to_s,
        description: accessibility_limitation_description
      )
    end

    def accessibility_assessment?
      accessibility_limitation? || availability_condition.present? || mobility_impaired_accessibility != 'unknown'
    end

    def accessibility_limitation?
      %i[
          wheelchair_accessibility step_free_accessibility escalator_free_accessibility
          lift_free_accessibility audible_signals_availability visual_signs_availability
        ].any? do |attribute|
        send(attribute) != :unknown
      end
    end
  end

  class ModelDecorator < SimpleDelegator
    def initialize(model, **attributes)
      super model

      attributes.each { |k,v| send "#{k}=", v }
    end

    def model
      __getobj__
    end

    attr_writer :alternate_identifiers_extractor

    def alternate_identifiers_extractor
      @alternate_identifiers_extractor ||= AlternateIdentifiersExtractor.new([])
    end

    def netex_alternate_identifiers
      alternate_identifiers_extractor.decorate(model).alternate_identifiers
    end

    attr_writer :code_provider

    def netex_identifier
      @netex_identifier ||= Code::Value.parse(code_provider.code(model))
    end

    def netex_attributes
      {
        id: netex_identifier.to_s,
        changed: updated_at,
        created: created_at
      }
    end

    def code_provider
      @code_provider ||= Export::CodeProvider.null
    end

    def decorate(model, **attributes)
      decorator_class = attributes.delete(:with) || default_decorator_class

      attributes = attributes.merge(
        alternate_identifiers_extractor: alternate_identifiers_extractor,
        code_provider: code_provider
      )
      decorator_class.new model, **attributes
    end
  end

  class StopDecorator < ModelDecorator
    include Accessibility

    def netex_attributes # rubocop:disable Metrics/MethodLength
      super.merge(
        {
          derived_from_object_ref: derived_from_object_ref,
          name: name,
          public_code: public_code,
          centroid: centroid,
          raw_xml: import_xml,
          key_list: key_list,
          accessibility_assessment: accessibility_assessment,
          postal_address: postal_address,
          url: url,
          transport_mode: netex_transport_mode,
          transport_submode: netex_transport_submode
        }.tap do |attributes|
          unless netex_quay?
            attributes[:parent_site_ref] = parent_site_ref
            attributes[:place_types] = place_types
          end
        end
      )
    end

    def netex_transport_mode
      transport_mode&.camelize_mode
    end

    def netex_transport_submode
      transport_mode&.camelize_sub_mode
    end

    def parent_objectid
      @parent_objectid ||= code_provider.stop_areas.code(parent_id)
    end

    def derived_from_object_ref
      code_provider.stop_areas.code(referent_id)
    end

    def key_list
      netex_alternate_identifiers + netex_custom_field_identifiers
    end

    def netex_custom_field_identifiers
      CustomFieldExtractor.new(self).custom_field_identifiers
    end

    def centroid
      Netex::Point.new(location: Netex::Location.new(longitude: longitude, latitude: latitude))
    end

    def parent_site_ref
      Netex::Reference.new(parent_objectid, type: 'StopPlace') if parent_objectid
    end

    def place_types
      [Netex::Reference.new(type_of_place, type: String)]
    end

    def type_of_place
      case area_type
      when Chouette::AreaType::QUAY
        'quay'
      when 'zdlp'
        'monomodalStopPlace'
      when 'lda'
        'generalStopPlace'
      when 'gdl'
        'groupOfStopPlaces'
      end
    end

    def postal_address_objectid
      netex_identifier&.change(type: 'PostalAddress').to_s
    end

    def postal_address
      Netex::PostalAddress.new(
        id: postal_address_objectid,
        address_line_1: street_name,
        post_code: zip_code,
        town: city_name,
        postal_region: postal_region,
        country_name: country_name
      )
    end

    def netex_resource
      netex_resource_class.new(netex_attributes).tap do |stop|
        if netex_quay?
          stop.with_tag parent_id: parent_objectid
        end
      end
    end

    def netex_quay?
      area_type&.to_sym == Chouette::AreaType::QUAY
    end

    def netex_resource_class
      netex_quay? ? Netex::Quay : Netex::StopPlace
    end
  end

  class Quays < Part

    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.where(area_type: Chouette::AreaType::QUAY).includes(:codes).find_each do |stop_area|
        netex_resource = decorate(stop_area, with: StopDecorator).netex_resource
        target << netex_resource
      end
    end

  end

  class StopPlaces < Part

    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.where.not(area_type: Chouette::AreaType::QUAY).includes(:codes, :entrances).find_each do |stop_area|
        stop_place = decorate(stop_area, with: StopDecorator).netex_resource
        target << stop_place
      end
    end

  end

  class Entrances < Part

    delegate :entrances, to: :export_scope

    def export!
      entrances.includes(:raw_import).find_each do |entrance|
        decorated_entrance = decorate(entrance)
        target << decorated_entrance.netex_resource
      end
    end

    class Decorator < ModelDecorator

      def netex_attributes
        super.merge(
          {
            name: name,
            short_name: short_name,
            description: description,
            centroid: centroid,
            postal_address: postal_address,
            entrance_type: entrance_type,
            is_entry: entry?,
            is_exit: exit?,
            raw_xml: raw_xml,
          }
        )
      end

      def netex_resource
        Netex::StopPlaceEntrance.new(netex_attributes).with_tag(parent_id: parent_objectid)
      end

      def centroid
        Netex::Point.new(
          location: Netex::Location.new(longitude: longitude, latitude: latitude)
        )
      end

      def postal_address_objectid
        netex_identifier&.change(type: 'PostalAddress').to_s
      end

      def postal_address
        Netex::PostalAddress.new(
          id: postal_address_objectid,
          address_line_1: address_line_1,
          post_code: zip_code,
          town: city_name,
          country_name: country
        )
      end

      def parent_objectid
        stop_area&.objectid
      end

      def raw_xml
        raw_import&.content
      end
    end
  end

  class PointOfInterests < Part

    def export!
      point_of_interests.find_each do |point_of_interest|
        decorated_point_of_interest = decorate(point_of_interest)
        target << decorated_point_of_interest.netex_resource
      end
    end

    def point_of_interests
      export_scope.point_of_interests
        .includes(:codes, :point_of_interest_hours)
        .joins(:point_of_interest_category)
        .select(
          "point_of_interests.*",
          "point_of_interest_categories.name AS category_name"
        )
    end

    class Decorator < ModelDecorator

      def netex_attributes
        {
          id: uuid,
          name: name,
          url: url,
          centroid: centroid,
          postal_address: postal_address,
          key_list: netex_alternate_identifiers,
          operating_organisation_view: operating_organisation_view,
          classifications: classifications,
          validity_conditions: validity_conditions,
        }
      end

      def netex_resource
        Netex::PointOfInterest.new(netex_attributes)
      end

      def centroid
        return unless longitude || latitude

        Netex::Point.new(
          location: Netex::Location.new(longitude: longitude, latitude: latitude)
        )
      end

      def postal_address
        Netex::PostalAddress.new(
          id: "Address:#{uuid}",
          address_line_1: address_line_1,
          post_code: zip_code,
          town: city_name,
          postal_region: postal_region,
          country_name: country
        )
      end

      def operating_organisation_view
        Netex::OperatingOrganisationView.new(
          contact_details: Netex::ContactDetails.new(
            phone: phone,
            email: email
          )
        )
      end

      def classifications
        [ Netex::PointOfInterestClassificationView.new(name: category_name) ]
      end

      def validity_conditions
        [].tap do |validity_conditions|
          point_of_interest_hours.find_each do |hour|
            validity_condition = ValidityCondition.new(hour, uuid)
            validity_conditions << Netex::AvailabilityCondition.new(
              day_types: validity_condition.day_types,
              timebands: validity_condition.timebands
            )
          end
        end
      end

      class ValidityCondition
        def initialize(hour, uuid)
          @hour = hour
          @uuid = uuid
        end
        attr_accessor :hour, :uuid

        def timebands
          [
            Netex::Timeband.new(
              id: id,
              start_time: start_time,
              end_time: end_time
            )
          ]
        end

        def day_types
          [
            Netex::DayType.new(
              id: id,
              properties: properties
            )
          ]
        end

        private

        def id
          "#{uuid}-#{hour.id}"
        end

        def start_time
          hour.opening_time_of_day.to_hms
        end

        def end_time
          hour.closing_time_of_day.to_hms
        end

        def properties
          [ Netex::PropertyOfDay.new(days_of_week: days_of_week) ]
        end

        def days_of_week
          all_days
            .select{ |day| contains_day?(day) }
            .map{ |day| day.to_s.capitalize }
            .join(' ')
        end

        def all_days
          @all_days ||= Cuckoo::Timetable::DaysOfWeek.all.days
        end

        def contains_day?(day)
          hour.week_days.send("#{day}?")
        end
      end
    end
  end

  class Lines < Part

    delegate :lines, to: :export_scope

    def export!
      export_scope.referenced_lines.pluck(:id, :referent_id).each do |line_id, referent_id|
        code_provider.lines.alias(line_id, as: referent_id)
      end

      lines.includes(:company, :codes).find_each do |line|
        resource_tagger.register_tag_for line
        tags = resource_tagger.tags_for(line.id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_line = decorate(line)
        tagged_target << decorated_line.netex_resource
      end
    end

    class Decorator < ModelDecorator
      include Accessibility

      def netex_attributes
        super.merge(
          {
            name: netex_name,
            transport_mode: transport_mode,
            transport_submode: netex_transport_submode,
            operator_ref: operator_ref,
            public_code: number,
            represented_by_group_ref: represented_by_group_ref,
            presentation: presentation,
            additional_operators: additional_operators,
            key_list: netex_alternate_identifiers,
            accessibility_assessment: accessibility_assessment,
            status: status,
            valid_between: valid_between,
            raw_xml: import_xml,
            derived_from_object_ref: derived_from_object_ref
          }
        )
      end

      def netex_name
        name || published_name
      end

      def valid_between
        return unless active_from.present? || active_until.present?

        from_date = active_from.present? ? active_from.beginning_of_day : nil
        to_date = active_until.present? ? (active_until + 1).beginning_of_day : nil

        Netex::ValidBetween.new(
          from_date: from_date,
          to_date: to_date
        )
      end

      def derived_from_object_ref
        code_provider.lines.code(referent_id)
      end

      def additional_operators
        return unless secondary_company_ids

        secondary_company_ids.map do |company_id|
          company_code = code_provider.companies.code(company_id)
          Netex::Reference.new(company_code, type: 'OperatorRef') if company_code
        end.compact
      end

      def status
        deactivated ? 'inactive' : ''
      end

      def netex_transport_submode
        transport_submode&.to_s unless transport_submode == :undefined
      end

      def presentation
        Netex::Presentation.new(text_colour: text_color&.downcase, colour: color&.downcase)
      end

      def netex_resource
        Netex::Line.new netex_attributes
      end

      def operator_ref
        company_code = code_provider.companies.code(company_id) if code_provider
        Netex::Reference.new(company_code, type: 'OperatorRef') if company_code
      end

      def represented_by_group_ref
        network_code = code_provider.networks.code(network_id) if code_provider
        Netex::Reference.new(network_code, type: 'NetworkRef') if network_code
      end

    end
  end

  class Companies < Part

    delegate :companies, to: :export_scope

    def export!
      companies.find_each do |company|
        decorated_company = decorate(company)
        target << decorated_company.netex_resource
      end
    end

    class Decorator < ModelDecorator

      def netex_attributes
        super.merge(
          {
            name: name,
            raw_xml: import_xml,
            key_list: netex_alternate_identifiers
          }
        )
      end

      def netex_resource
        Netex::Operator.new netex_attributes
      end
    end

  end

  class Networks < Part

    delegate :networks, to: :export_scope

    def export!
      networks.find_each do |network|
        decorated_network = decorate(network)
        target << decorated_network.netex_resource
      end
    end

    class Decorator < ModelDecorator

      def netex_attributes
        super.merge(
          {
            name: name,
            raw_xml: import_xml
          }
        )
      end

      def netex_resource
        Netex::Network.new netex_attributes
      end

    end

  end

  module StopPointDecorator
    class Base < SimpleDelegator
      def initialize(stop_point, **attributes)
        super stop_point

        attributes.each do |k,v|
          writer_method = "#{k}="
          send writer_method, v if respond_to?(writer_method)
        end
      end

      def stop_point
        __getobj__
      end

      def netex_identifier
        # Use stop_points.code to support more easily PseudoStopPoint
        @netex_identifier ||= Code::Value.parse(stop_point_code)
      end

      def stop_point_code
        code_provider.stop_points.code(stop_point.id)
      end

      attr_writer :code_provider

      def code_provider
        @code_provider ||= Export::CodeProvider.null
      end

      def netex_order
        position+1
      end

      attr_writer :data_source_ref

      def data_source_ref
        stop_point.try(:data_source_ref) || @data_source_ref
      end

      def decorate(with:)
        with.new(stop_point, code_provider: code_provider)
      end
    end

    # <Route ...>
    #   <pointsInSequence>
    #     <PointOnRoute id="chouette:PointOnRoute:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any" order="1">
    #       <RoutePointRef ref="chouette:RoutePoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any"/>
    #     </PointOnRoute>
    #     <PointOnRoute id="chouette:PointOnRoute:95c5bfc9-62f9-4490-9a57-3fa2fd6c3013:LOC" version="any" order="2">
    #       <RoutePointRef ref="chouette:RoutePoint:95c5bfc9-62f9-4490-9a57-3fa2fd6c3013:LOC" version="any"/>
    #     </PointOnRoute>
    #   </pointsInSequence>
    # </Route>
    class PointOnRoute < Base
      def point_on_route
        Netex::PointOnRoute.new point_on_route_attributes
      end

      def netex_identifier
        @netex_identifier ||= super.change(type: 'PointOnRoute')
      end

      def point_on_route_attributes
        {
          id: netex_identifier.to_s,
          order: netex_order,
          route_point_ref: route_point_ref
        }
      end

      def route_point_ref
        decorate(with: RoutePoint).route_point_ref
      end
    end

    # Create a RoutePoint or a RoutePointRef from a Chouette::StopPoint
    #
    # <RoutePoint id="chouette:RoutePoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any">
    #   <projections>
    #     <PointProjection id="chouette:PointProjection:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any">
    #       <ProjectToPointRef ref="chouette:ScheduledStopPoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any"/>
    #     </PointProjection>
    #   </projections>
    # </RoutePoint>
    class RoutePoint < Base
      def route_point
        Netex::RoutePoint.new(route_point_attributes)
      end

      def route_point_attributes
        {
          id: netex_identifier.to_s,
          projections: point_projection,
          data_source_ref: data_source_ref
        }
      end

      def netex_identifier
        @netex_identifier ||= super.change(type: 'RoutePoint')
      end

      def route_point_ref
        Netex::Reference.new(netex_identifier.to_s, type: 'RoutePointRef')
      end

      def point_projection
        [Netex::PointProjection.new(point_projection_attributes)]
      end

      def point_projection_attributes
        {
          id: point_projection_id,
          project_to_point_ref: scheduled_stop_point_ref
        }
      end

      def point_projection_id
        netex_identifier.change(type: 'PointProjection').to_s
      end

      def scheduled_stop_point_ref
        decorate(with: ScheduledStopPoint).scheduled_stop_point_ref
      end
    end

    # Create ScheduledStopPoint or ScheduledStopPointRef from a Chouette::StopPoint
    #
    #   <ScheduledStopPoint id="chouette:ScheduledStopPoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any"/>
    #   <ScheduledStopPointRef ref="chouette:ScheduledStopPoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC"/>
    class ScheduledStopPoint < Base
      def scheduled_stop_point
        Netex::ScheduledStopPoint.new(scheduled_stop_point_attributes)
      end

      def scheduled_stop_point_ref
        Netex::Reference.new(netex_identifier.to_s, type: 'ScheduledStopPointRef')
      end

      def scheduled_stop_point_attributes
        {
          id: netex_identifier.to_s,
          data_source_ref: data_source_ref
        }
      end

      def netex_identifier
        @netex_identifier ||= super&.change(type: 'ScheduledStopPoint')
      end
    end

    # Create a PassengerStopAssignment from a Chouette::StopPoint
    #
    # <PassengerStopAssignment id="chouette:PassengerStopAssignment:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any" order="0">
    #   <ScheduledStopPointRef ref="chouette:ScheduledStopPoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any"/>
    #   <QuayRef ref="chouette:StopArea:fe90c70f-d9ac-45cd-b044-0d4adcfaa997:LOC"/>
    # </PassengerStopAssignment>
    class PassengerStopAssignment < Base
      def netex_identifier
        @netex_identifier ||= super&.change(type: 'PassengerStopAssignment')
      end

      def stop_area_code
        code_provider.stop_areas.code(stop_area_id)
      end

      def stop_area_area_type
        __getobj__.try(:stop_area_area_type) || stop_area&.area_type
      end

      def netex_quay?
        stop_area_area_type&.to_sym == Chouette::AreaType::QUAY
      end

      def passenger_stop_assignment
        Netex::PassengerStopAssignment.new(passenger_stop_assignment_attributes).tap do |passenger_stop_assignment|
          if netex_quay?
            passenger_stop_assignment.quay_ref = quay_ref
          else
            passenger_stop_assignment.stop_place_ref = stop_place_ref
          end
        end
      end

      def passenger_stop_assignment_attributes
        {
          id: netex_identifier.to_s,
          data_source_ref: data_source_ref,
          order: 0,
          scheduled_stop_point_ref: scheduled_stop_point_ref
        }
      end

      def quay_ref
        Netex::Reference.new(stop_area_code, type: 'QuayRef')
      end

      def stop_place_ref
        Netex::Reference.new(stop_area_code, type: 'StopPlaceRef')
      end

      def scheduled_stop_point_ref
        decorate(with: ScheduledStopPoint).scheduled_stop_point_ref
      end
    end

    # Create a StopPointInJourneyPattern from a Chouette::StopPoint and a JourneyPattern identifier
    # <ServiceJourneyPattern ...>
    #   <pointsInSequence>
    #     <StopPointInJourneyPattern id="chouette:StopPointInJourneyPattern:6969284b-5a42-46a5-b5e1-ae3d2d35bd23-2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any" order="1">
    #       <ScheduledStopPointRef ref="chouette:ScheduledStopPoint:2f924949-e287-4f10-bbe0-4a50f9debf9e:LOC" version="any"/>
    #       <ForAlighting>true</ForAlighting>
    #       <ForBoarding>true</ForBoarding>
    #     </StopPointInJourneyPattern>
    #     <StopPointInJourneyPattern id="chouette:StopPointInJourneyPattern:6969284b-5a42-46a5-b5e1-ae3d2d35bd23-95c5bfc9-62f9-4490-9a57-3fa2fd6c3013:LOC" version="any" order="2">
    #       <ScheduledStopPointRef ref="chouette:ScheduledStopPoint:95c5bfc9-62f9-4490-9a57-3fa2fd6c3013:LOC" version="any"/>
    #       <ForAlighting>true</ForAlighting>
    #       <ForBoarding>true</ForBoarding>
    #     </StopPointInJourneyPattern>
    #   </pointsInSequence>
    # </ServiceJourneyPattern>
    class StopPointInJourneyPattern < Base
      def initialize(stop_point, journey_pattern_id:, **attributes)
        super stop_point, attributes
        @journey_pattern_id = journey_pattern_id
      end

      attr_reader :journey_pattern_id

      def stop_point_in_journey_pattern
        Netex::StopPointInJourneyPattern.new stop_point_in_journey_pattern_attributes
      end

      def stop_point_in_journey_pattern_ref
        Netex::Reference.new(netex_identifier.to_s, type: Netex::StopPointInJourneyPattern)
      end

      def stop_point_in_journey_pattern_attributes
        {
          id: netex_identifier.to_s,
          order: netex_order,
          scheduled_stop_point_ref: scheduled_stop_point_ref,
          for_boarding: netex_for_boarding,
          for_alighting: netex_for_alighting
        }
      end

      def netex_identifier
        @netex_identifier ||= super.merge(Code::Value.parse(journey_pattern_code), type: "StopPointInJourneyPattern")
      end

      def journey_pattern_code
        code_provider.journey_patterns.code(journey_pattern_id)
      end

      def netex_for_boarding
        for_boarding == "normal"
      end

      def netex_for_alighting
        for_alighting == "normal"
      end

      def scheduled_stop_point_ref
        decorate(with: ScheduledStopPoint).scheduled_stop_point_ref
      end
    end

    # Creates a 'pseudo' StopPoint with only id attribute
    # Allows to use (some) Decorators from a stop_point_id
    #
    #   pseudo_stop_point = StopPointDecorator.pseudo_stop_point(id: stop_point_id)
    #   decorate(pseudo_stop_point, journey_pattern_id: journey_pattern_id, with: StopPointDecorator::StopPointInJourneyPattern)
    #
    def self.pseudo_stop_point(**attributes)
      PseudoStopPoint.new(**attributes)
    end

    class PseudoStopPoint
      def initialize(id:)
        @id = id
      end

      attr_reader :id
    end
  end

  class Routes < Part

    delegate :routes, to: :export_scope

    def export!
      routes.includes(:line, :stop_points, :codes).find_each do |route|
        tags = resource_tagger.tags_for(route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_route = decorate(route)
        # Export Direction before the Route to detect local reference
        tagged_target << decorated_route.direction if decorated_route.direction
        tagged_target << decorated_route.netex_resource

        decorated_route.routing_constraint_zones.each do |zone|
          tagged_target << zone
        end
      end
    end

    class Decorator < ModelDecorator

      delegate :line_routing_constraint_zones, to: :line

      def netex_attributes
        super.merge(
          {
            data_source_ref: data_source_ref,
            name: netex_name,
            line_ref: line_ref,
            direction_ref: direction_ref,
            direction_type: direction_type,
            points_in_sequence: points_in_sequence,
            key_list: netex_alternate_identifiers
          }.tap do |attributes|
            attributes[:direction_ref] = direction_ref if published_name.present?
          end
        )
      end

      def netex_resource
        Netex::Route.new netex_attributes
      end

      def netex_name
        published_name.presence || name
      end

      def direction_id
        netex_identifier.change(type: 'Direction').to_s
      end

      def direction
        @direction ||= Netex::Direction.new(
          id: direction_id,
          data_source_ref: data_source_ref,
          name: published_name
        ) if published_name
      end

      def direction_ref
        Netex::Reference.new(direction_id, type: 'DirectionRef') if direction
      end

      def direction_type
        wayback.to_s
      end

      def line_ref
        if line_code = code_provider.lines.code(line_id)
          Netex::Reference.new(line_code, type: Netex::Line)
        end
      end

      def points_in_sequence
        decorated_point_on_routes.map(&:point_on_route)
      end

      def decorated_point_on_routes
        @decorated_stop_points ||= stop_points.map do |stop_point|
          decorate(stop_point, data_source_ref: data_source_ref, with: StopPointDecorator::PointOnRoute)
        end
      end

      def stop_area_ids
        @stop_area_ids ||= stop_points.map(&:stop_area_id)
      end

      def filter_line_routing_constraint_zones
        line_routing_constraint_zones.select do |line_routing_constraint_zone|
          (line_routing_constraint_zone.stop_area_ids & stop_area_ids).many?
        end
      end

      def routing_constraint_zones
        filter_line_routing_constraint_zones.map do |line_routing_constraint_zone|
          LineRoutingConstraintZoneDecorator.new(line_routing_constraint_zone, route: self, code_provider: code_provider).netex_resource
        end
      end

      class LineRoutingConstraintZoneDecorator < ModelDecorator
        delegate :line, to: :route

        attr_accessor :route

        def netex_attributes
          {
            id: merged_id,
            name: name,
            members: scheduled_stop_point_refs,
            lines: line_refs,
            zone_use: zone_use
          }
        end

        def merged_id
          Code::Value.merge(code_provider.code(route), id, type: "RoutingConstraintZone")
        end

        def zone_use
          "cannotBoardAndAlightInSameZone"
        end

        def line_refs
          if line_code = code_provider.lines.code(route.line_id)
            [Netex::Reference.new(line_code, type: 'LineRef')]
          end
        end

        def stop_points
          route.stop_points.select { |stop_point| stop_area_ids.include? stop_point.stop_area_id }
        end

        def scheduled_stop_point_refs
          stop_points.map do |stop_point|
            decorate(stop_point, with: StopPointDecorator::ScheduledStopPoint).scheduled_stop_point_ref
          end
        end

        def netex_resource
          Netex::RoutingConstraintZone.new netex_attributes
        end
      end
    end

  end

  class StopPoints < Part

    delegate :stop_points, to: :export_scope

    def export!
      stop_points.joins(:route, :stop_area).select(selected).find_each_light do |stop_point|
        tags = resource_tagger.tags_for(stop_point.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        tagged_target <<
          decorate(stop_point, with: StopPointDecorator::ScheduledStopPoint).scheduled_stop_point
        tagged_target <<
          decorate(stop_point, with: StopPointDecorator::PassengerStopAssignment).passenger_stop_assignment
        tagged_target <<
          decorate(stop_point, with: StopPointDecorator::RoutePoint).route_point
      end
    end

    private

    def selected
      [
        'stop_points.*',
        'stop_areas.area_type AS stop_area_area_type',
        'routes.line_id AS line_id',
        'routes.data_source_ref AS data_source_ref',
      ]
    end
  end

  class RoutingConstraintZones < Part

    delegate :routing_constraint_zones, to: :export_scope

    def export!
      routing_constraint_zones.includes(:route).find_each do |routing_constraint_zone|
        tags = resource_tagger.tags_for(routing_constraint_zone.route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_zone = decorate(routing_constraint_zone)
        tagged_target << decorated_zone.netex_resource
      end
    end

    class Decorator < ModelDecorator

      def netex_attributes
        super.merge(
          {
            data_source_ref: data_source_ref,
            name: name,
            members: scheduled_stop_point_refs,
            lines: line_refs,
            zone_use: zone_use
          }
        )
      end

      def scheduled_stop_point_refs
        stop_points.map do |stop_point|
          decorate(stop_point, with: StopPointDecorator::ScheduledStopPoint).scheduled_stop_point_ref
        end
      end

      def line_refs
        if line_code = code_provider.lines.code(route.line_id)
          [ Netex::Reference.new(line_code, type: 'LineRef') ]
        end
      end

      def netex_resource
        Netex::RoutingConstraintZone.new netex_attributes
      end

      def zone_use
        "cannotBoardAndAlightInSameZone"
      end
    end
  end

  class JourneyPatterns < Part

    delegate :journey_patterns, to: :export_scope

    def export!
      journey_patterns.includes(:route, :codes, :stop_points).find_each do |journey_pattern|
        tags = resource_tagger.tags_for(journey_pattern.route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_journey_pattern = decorate(journey_pattern)
        # Export Destination Displays before the JourneyPattern to detect local reference
        tagged_target << decorated_journey_pattern.destination_display if journey_pattern.published_name.present?
        tagged_target << decorated_journey_pattern.netex_resource
      end
    end

    class Decorator < ModelDecorator

      def netex_attributes
        super.merge(
          {
            data_source_ref: data_source_ref,
            name: name,
            route_ref: route_ref,
            points_in_sequence: points_in_sequence,
            key_list: netex_alternate_identifiers
          }.tap do |attributes|
            attributes[:destination_display_ref] = destination_display_ref if published_name.present?
          end
        )
      end

      def netex_resource
        Netex::ServiceJourneyPattern.new netex_attributes
      end

      def route_ref
        Netex::Reference.new(code_provider.routes.code(route_id), type: 'RouteRef')
      end

      def destination_display_id
        netex_identifier.change(type: 'DestinationDisplay').to_s
      end

      def destination_display
        @destination_display ||= Netex::DestinationDisplay.new(
          id: destination_display_id,
          data_source_ref: data_source_ref,
          front_text: published_name
        )
      end

      def destination_display_ref
        Netex::Reference.new(destination_display_id, type: Netex::DestinationDisplay)
      end

      def points_in_sequence
        decorated_stop_points.map(&:stop_point_in_journey_pattern)
      end

      def decorated_stop_points
        @decorated_stop_points ||= stop_points.map do |stop_point|
          decorate(stop_point, journey_pattern_id: id, with: StopPointDecorator::StopPointInJourneyPattern)
        end
      end
    end
  end

  class VehicleJourneyAtStops < Part
    def export!
      vehicle_journey_at_stops.find_each_light do |light_vehicle_journey_at_stop|
        decorated_vehicle_journey_at_stop = decorate(light_vehicle_journey_at_stop)
        target << decorated_vehicle_journey_at_stop.netex_resource
      end
    end

    def vehicle_journey_at_stops
      export_scope.vehicle_journey_at_stops
        .joins(stop_point: :stop_area, vehicle_journey: { journey_pattern: :route })
        .order(:vehicle_journey_id, "stop_points.position": :asc)
        .select(
          "vehicle_journey_at_stops.*",
          "vehicle_journeys.journey_pattern_id AS journey_pattern_id",
          "vehicle_journeys.id AS vehicle_journey_id",
          "stop_areas.time_zone AS time_zone",
        )
    end

    class Decorator < ModelDecorator
      def netex_attributes
        {
          departure_time: stop_time_departure_time,
          arrival_time: stop_time_arrival_time,
          departure_day_offset: departure_day_offset,
          arrival_day_offset: arrival_day_offset,
          stop_point_in_journey_pattern_ref: stop_point_in_journey_pattern_ref,
        }
      end

      def netex_resource
        Netex::TimetabledPassingTime.new(netex_attributes).with_tag(parent_id: parent_code)
      end

      def parent_code
        code_provider.vehicle_journeys.code(vehicle_journey_id)
      end

      def journey_pattern_id
        __getobj__.try(:journey_pattern_id) || journey_pattern&.id
      end

      def decorated_stop_point
        decorate(pseudo_stop_point, journey_pattern_id: journey_pattern_id, with: StopPointDecorator::StopPointInJourneyPattern)
      end
      delegate :stop_point_in_journey_pattern_ref, to: :decorated_stop_point

      def pseudo_stop_point
        StopPointDecorator.pseudo_stop_point(id: stop_point_id)
      end

      def netex_time time_of_day
        Netex::Time.new time_of_day.hour, time_of_day.minute, time_of_day.second
      end

      def stop_time_arrival_time
        netex_time arrival_local_time_of_day if arrival_local_time_of_day
      end

      def stop_time_departure_time
        netex_time departure_local_time_of_day if departure_local_time_of_day
      end
    end
  end

  class VehicleJourneys < Part
    def export!
      vehicle_journeys.each_instance do |vehicle_journey|
        tags = resource_tagger.tags_for(vehicle_journey.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_vehicle_journey = decorate(vehicle_journey, code_space_keys: code_space_keys)
        tagged_target << decorated_vehicle_journey.netex_resource
      end
    end

    def vehicle_journeys
      Query.new(export_scope.vehicle_journeys).scope
    end

    # TODO: integrate this use case in AlternateIdentifiersExtractor
    def code_space_keys
      @code_space_keys ||= workgroup.code_spaces.pluck(:id, :short_name).to_h
    end

    class Query

      def initialize(vehicle_journeys)
        @vehicle_journeys = vehicle_journeys
      end
      attr_accessor :vehicle_journeys

      def scope
        scope = vehicle_journeys.joins(:route).select(selected)

        scope = scope.left_joins(:codes).select(vehicle_journey_codes).group(group_by)
        scope.joins(:vehicle_journey_time_table_relationships).select(time_table_ids)
      end

      private

      def selected
        <<~SQL
          vehicle_journeys.*,
          routes.line_id AS line_id
        SQL
      end

      def time_table_ids
        <<~SQL
          array_agg(DISTINCT time_tables_vehicle_journeys.time_table_id) AS timetable_ids
        SQL
      end

      def vehicle_journey_codes
        <<~SQL
          array_agg(
            DISTINCT
            jsonb_build_object(
              'id', referential_codes.code_space_id,
              'value', referential_codes.value
            )
          ) AS vehicle_journey_codes
        SQL
      end

      def group_by
        <<~SQL
          vehicle_journeys.id,
          routes.line_id
        SQL
      end
    end

    class Decorator < ModelDecorator

      attr_accessor :code_space_keys

      def netex_attributes
        super.merge(
          {
            data_source_ref: data_source_ref,
            name: published_journey_name,
            journey_pattern_ref: journey_pattern_ref,
            public_code: published_journey_identifier,
            day_types: day_types,
            key_list: netex_alternate_identifiers
          }
        )
      end

      def netex_resource
        Netex::ServiceJourney.new netex_attributes
      end

      def code_space_key(code_space_id)
        code_space_keys[code_space_id]
      end

      def netex_alternate_identifiers
        return if code_space_keys.blank? || try(:vehicle_journey_codes).blank?

        vehicle_journey_codes.map do |vehicle_journey_code|
          Netex::KeyValue.new(
            key: code_space_key(vehicle_journey_code['id'].to_i),
            value: vehicle_journey_code['value'],
            type_of_key: 'ALTERNATE_IDENTIFIER'
          )
        end
      end

      def journey_pattern_ref
        Netex::Reference.new(journey_pattern_code, type: 'JourneyPatternRef')
      end

      def journey_pattern_code
        code_provider.journey_patterns.code(journey_pattern_id)
      end

      def timetable_codes
        if identifiers = try(:timetable_ids)
          code_provider.time_tables.codes(identifiers)
        else
          code_provider.codes(time_tables)
        end
      end

      def day_types
        timetable_codes.map do |code|
          Netex::Reference.new(code, type: 'DayTypeRef')
        end
      end
    end
  end

  class VehicleJourneyStopAssignments < Part
    def export!
      vehicle_journey_at_stops.find_each do |vehicle_journey_at_stop|
        tags = resource_tagger.tags_for(vehicle_journey_at_stop.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        netex_resource = Decorator.new(vehicle_journey_at_stop).netex_resource
        tagged_target << netex_resource
      end
    end

    def vehicle_journey_at_stops
      export_scope.vehicle_journey_at_stops.where.not(stop_area: nil)
                  .joins(:stop_point, :stop_area, vehicle_journey: :route)
                  .select(*selected_columns)
    end

    def selected_columns
      ['vehicle_journey_at_stops.*',
       'vehicle_journeys.objectid AS vehicle_journey_objectid',
       "COALESCE(vehicle_journeys.data_source_ref, 'none') AS vehicle_journey_data_source_ref",
       'stop_points.objectid AS stop_point_objectid',
       'stop_areas.objectid AS stop_area_objectid',
       'stop_points.position AS stop_point_position',
       'routes.line_id as line_id'
      ]
    end

    class Decorator < SimpleDelegator
      def netex_attributes
        {
          id: objectid,
          data_source_ref: vehicle_journey_data_source_ref,
          scheduled_stop_point_ref: scheduled_stop_point_ref,
          stop_place_ref: stop_place_ref,
          quay_ref: quay_ref,
          vehicle_journey_refs: vehicle_journey_refs
        }
      end

      def netex_resource
        Netex::VehicleJourneyStopAssignment.new(netex_attributes)
      end

      def objectid
        Code::Value.merge(vehicle_journey_objectid, stop_point_position, type: 'VehicleJourneyStopAssignment').to_s
      end

      def stop_point_position
        __getobj__.try(:stop_point_position) || stop_point&.position
      end

      def stop_point_objectid
        __getobj__.try(:stop_point_objectid) || stop_point&.objectid
      end

      def stop_area_objectid
        __getobj__.try(:stop_area_objectid) || stop_area&.objectid
      end

      def vehicle_journey_objectid
        __getobj__.try(:vehicle_journey_objectid) || vehicle_journey&.objectid
      end

      def vehicle_journey_data_source_ref
        loaded_value = __getobj__.try(:vehicle_journey_data_source_ref)
        return nil if loaded_value == 'none'

        loaded_value || vehicle_journey&.data_source_ref
      end

      def scheduled_stop_point_ref
        Netex::Reference.new(stop_point_objectid, type: 'ScheduledStopPointRef')
      end

      def stop_place_ref
        Netex::Reference.new(stop_area_objectid, type: 'StopPlaceRef')
      end

      def quay_ref
        Netex::Reference.new(stop_area_objectid, type: 'QuayRef')
      end

      def vehicle_journey_refs
        [Netex::Reference.new(vehicle_journey_objectid, type: 'ServiceJourney')]
      end
    end
  end

  class PeriodDecorator < SimpleDelegator

    attr_accessor :day_type_ref, :time_table, :code_provider
    def initialize(period, day_type_ref, code_provider = nil)
      super period

      @day_type_ref = day_type_ref
      @time_table = period.time_table
      @code_provider = code_provider
    end

    def netex_identifier
      @netex_identifier ||= begin
        code_time_table = code_provider.time_tables.code(time_table.id) if code_provider
        Code::Value.parse(code_time_table) if code_time_table
      end
    end

    def operating_period
      Netex::OperatingPeriod.new operating_period_attributes
    end

    def operating_period_id
      netex_identifier&.merge(id, type: 'OperatingPeriod').to_s
    end

    def operating_period_attributes
      {
        id: operating_period_id,
        data_source_ref: time_table.data_source_ref,
        from_date: period_start,
        to_date: period_end
      }
    end

    def day_type_assignment_id
      netex_identifier&.merge("p#{id}", type: 'DayTypeAssignment').to_s
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def day_type_assignment_attributes
      {
        id: day_type_assignment_id,
        data_source_ref: time_table.data_source_ref,
        operating_period_ref: operating_period_ref,
        day_type_ref: day_type_ref,
        order: 0
      }
    end

    def operating_period_ref
      Netex::Reference.new(operating_period_id, type: 'OperatingPeriodRef')
    end

  end

  class DateDecorator < SimpleDelegator

    attr_accessor :day_type_ref, :time_table, :code_provider
    def initialize(date, day_type_ref, code_provider = nil)
      super date

      @day_type_ref = day_type_ref
      @time_table = date.time_table
      @code_provider = code_provider
    end

    def netex_identifier
      @netex_identifier ||= begin
        code_time_table = code_provider.time_tables.code(time_table.id) if code_provider
        Code::Value.parse(code_time_table) if code_time_table
      end
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def date_type_assignment_id
      netex_identifier&.merge("d#{id}", type: 'DayTypeAssignment').to_s
    end

    def day_type_assignment_attributes
      {
        id: date_type_assignment_id,
        data_source_ref: time_table.data_source_ref,
        date: date,
        is_available: in_out,
        day_type_ref: day_type_ref,
        order: 0
      }
    end

  end

  class TimeTables < Part
    delegate :time_tables, to: :export_scope
    delegate :validity_period, to: :export_scope

    def export!
      time_tables.includes(:periods, :dates, :lines, :codes).find_each do |time_table|
        decorated_time_table = decorate(time_table, validity_period: validity_period)

        tags = resource_tagger.tags_for_lines(time_table.line_ids)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_time_table.netex_resources.each do |resource|
          tagged_target << resource
        end
      end
    end

    class Decorator < ModelDecorator
      attr_accessor :validity_period

      def netex_resources
        return [] unless day_type_assignment?

        [day_type, exported_periods, exported_dates].flatten
      end

      def day_type_assignment?
        decorated_dates.present? || decorated_periods.present?
      end

      def day_type
        Netex::DayType.new day_type_attributes
      end

      def day_type_attributes
        {
          id: netex_identifier.to_s,
          data_source_ref: data_source_ref,
          name: comment,
          properties: properties,
          key_list: netex_alternate_identifiers
        }
      end

      def day_type_ref
        @day_type_ref ||= Netex::Reference.new(netex_identifier.to_s, type: 'DayTypeRef')
      end

      def properties
        [Netex::PropertyOfDay.new(days_of_week: days_of_week)]
      end

      DAYS = %w{monday tuesday wednesday thursday friday saturday sunday}
      def days_of_week
        DAYS.map { |day| day.capitalize if send(day) }.compact.join(' ')
      end

      def exported_periods
        decorated_periods.map(&:operating_period) + decorated_periods.map(&:day_type_assignment)
      end

      def candidate_periods
        @candidate_periods ||= validity_period ? periods.select { |period| period.intersect?(validity_period) } : periods
      end

      def decorated_periods
        @decorated_periods ||= candidate_periods.map do |period|
          PeriodDecorator.new(period, day_type_ref, code_provider)
        end
      end

      def candidate_excluded_dates
        dates.select(&:excluded?).select do |date|
          candidate_periods.any? { |period| period.include? date.date }
        end
      end

      def candidate_included_dates
        included_dates = dates.select(&:included?)
        return included_dates unless validity_period

        included_dates.select { |date| validity_period.include? date.date }
      end

      def candidate_dates
        candidate_excluded_dates + candidate_included_dates
      end

      def exported_dates
        decorated_dates.map(&:day_type_assignment)
      end

      def decorated_dates
        @decorated_dates ||= candidate_dates.map do |date|
          DateDecorator.new(date, day_type_ref, code_provider)
        end
      end
    end
  end

  class Organisations < Part
    delegate :organisations, to: :export_scope

    def export!
      organisations.find_each do |o|
        target << Decorator.new(o).netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_resource
        Netex::GeneralOrganisation.new(id: code, name: name)
      end
    end
  end

end
