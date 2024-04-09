# frozen_string_literal: true

# Export a dataset into a Ara CSV file
require 'ara/file'
class Export::Ara < Export::Base
  include LocalExportSupport

  # FIXME: Should be shared
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :exported_lines, default_value: 'all_line_ids',
                          enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :duration # Ignored by this export .. but required by Export::Scope builder
  option :include_stop_visits

  skip_empty_exports

  def content_type
    'application/csv'
  end

  def file_extension
    'csv'
  end

  # TODO: Should be shared
  def export_file
    @export_file ||= Tempfile.new(["export#{id}", ".#{file_extension}"])
  end

  def target
    @target ||= ::Ara::File::Target.new export_file
  end
  attr_writer :target

  def period
    @period ||=
      begin
        today = Time.zone.today
        today..today + 5
      end
  end

  alias include_stop_visits? include_stop_visits

  def parts
    @parts ||= [Stops, Lines, Companies, VehicleJourneys].tap do |parts|
      parts << StopVisits if include_stop_visits?
    end
  end

  def generate_export_file
    period.each do |day|
      # For each day, a scope selects models to be exported
      daily_scope = DailyScope.new export_scope, day

      target.model_name(day) do |model_name|
        # For each day, each kind of model is exported
        parts.each do |part|
          part.new(context: Context.new(self), export_scope: daily_scope, target: model_name).export
        end
      end
    end

    target.close

    export_file.close
    export_file
  end

  # Provides (restricted) access to Export resources in Part
  class Context
    def initialize(export)
      @export = export
    end
    attr_reader :export

    delegate :referential, to: :export
    delegate :stop_area_referential, to: :referential
  end

  # Use Export::Scope::Scheduled which scopes all models according to vehicle_journeys
  class DailyScope < Export::Scope::Scheduled
    def initialize(export_scope, day)
      super export_scope
      @day = day
    end

    attr_reader :day

    def vehicle_journeys
      @vehicle_journeys ||= current_scope.vehicle_journeys.scheduled_on(day)
    end
  end

  # TODO: To be shared
  module CodeProvider
    # Manage all CodeSpace for a Model class (StopArea, VehicleJourney, ...)
    class Model
      def initialize(scope:, model_class:)
        @scope = scope
        @model_class = model_class
      end

      attr_reader :scope, :model_class

      # For the given model (StopArea, VehicleJourney, ..), returns all codes which are uniq.
      def unique_codes(model)
        unique_codes = {}

        if model.respond_to?(:codes)
          code_spaces = model.codes.map(&:code_space).uniq

          unique_codes = code_spaces.map do |code_space|
            code_provider = code_providers[code_space]

            unique_code = code_provider.unique_code(model)
            [code_provider.short_name, unique_code] if unique_code
          end.compact.to_h
        end

        # Use registration_number as legacy mode
        if model.respond_to?(:registration_number) &&
           !unique_codes.key?(registration_number_provider.short_name)

          unique_code = registration_number_provider.unique_code(model)
          unique_codes[registration_number_provider.short_name] = unique_code if unique_code
        end

        unique_codes['external'] ||= model.objectid if model.respond_to?(:objectid) && !unique_codes.key?('external')

        unique_codes
      end

      # Provide (unique) value from registration provider
      def registration_number_provider
        @registration_number_provider ||=
          CodeProvider::RegistrationNumber.new scope: scope,
                                               model_class: model_class
      end

      # Provide (unique) value for each Code Space
      def code_providers
        @code_providers ||= Hash.new do |h, code_space|
          h[code_space] =
            CodeProvider::CodeSpace.new scope: scope,
                                        code_space: code_space,
                                        model_class: model_class
        end
      end

      # Returns a default implementation which simply returns all model codes
      # Can be used instead of a real CodeProvider::Model when the context is not ready
      def self.null
        @null ||= Null.new
      end

      class Null
        def unique_codes(model)
          model.codes.map do |code|
            [code.code_space.short_name, code.value]
          end.to_h
        end
      end
    end

    # Manage registration number attribute as a code space
    class RegistrationNumber
      def initialize(scope:, model_class:)
        @scope = scope
        @model_class = model_class
      end
      attr_reader :scope, :model_class

      def short_name
        'external'
      end

      def unique_code(model)
        candidate_value = model.registration_number
        return nil if candidate_value.blank?
        return nil if duplicated?(candidate_value)

        candidate_value
      end

      def duplicated?(code_value)
        duplicated_registration_numbers.include? code_value
      end

      def model_collection
        model_class.model_name.plural
      end

      def models
        scope.send model_collection
      end

      def duplicated_registration_numbers
        # CHOUETTE-1787 Use model_class to load models before grouping it
        @duplicated_registration_numbers ||=
          begin
            registration_numbers = model_class
                                   .where(id: models.select(:id))
                                   .where.not(registration_number: nil)
                                   .group(:registration_number)
                                   .having("count(#{model_class.model_name.plural}.id) > 1")
                                   .pluck(:registration_number)

            SortedSet.new registration_numbers
          end
      end
    end

    # Manage a single CodeSpace for a Model class
    # TODO To be used in Export::Gtfs
    class CodeSpace
      def initialize(scope:, code_space:, model_class:)
        @scope = scope
        @code_space = code_space
        @model_class = model_class
      end

      attr_reader :scope, :code_space, :model_class

      delegate :short_name, to: :code_space

      # Returns the code value for the given Resource if uniq
      def unique_code(model)
        candidates = candidate_codes(model)
        return nil unless candidates.one?

        candidate_value = candidates.first.value
        return nil if duplicated?(candidate_value)

        candidate_value
      end

      def candidate_codes(model)
        model.codes.select { |code| code.code_space_id == code_space.id }
      end

      def duplicated?(code_value)
        duplicated_code_values.include? code_value
      end

      def model_collection
        model_class.model_name.plural
      end

      def models
        scope.send model_collection
      end

      def model_codes
        codes.where(code_space: code_space, resource: models)
      end

      def codes
        # FIXME
        if model_class == Chouette::VehicleJourney
          scope.referential_codes
        else
          scope.codes
        end
      end

      def duplicated_code_values
        @duplicated_code_values ||=
          SortedSet.new(model_codes.select(:value,
                                           :resource_id).group(:value).having('count(resource_id) > 1').pluck(:value))
      end
    end
  end

  class Part
    attr_reader :context, :export_scope, :target

    def initialize(export_scope:, target:, context: nil)
      @context = context
      @export_scope = export_scope
      @target = target
    end

    def name
      @name ||= self.class.name.demodulize.underscore
    end

    def export
      Chouette::Benchmark.measure name do
        export!
      end
    end
  end

  delegate :stop_area_referential, to: :referential

  class Scope < SimpleDelegator
    def initialize(export_scope, export:)
      super export_scope

      @export = export
    end

    def export_scope
      __getobj__
    end

    attr_reader :export
    delegate :stop_area_referential, to: :export

    def stop_areas
      @stop_areas ||= ::Query::StopArea.new(stop_area_referential.stop_areas).self_referents_and_ancestors(export_scope.stop_areas)
    end
  end

  def export_scope
    @local_export_scope ||= Scope.new(super, export: self)
  end

  class Stops < Part
    delegate :stop_area_referential, to: :context
    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.includes(:parent, :referent, :lines, codes: :code_space).find_each do |stop_area|
        target << Decorator.new(stop_area, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      @code_provider ||= CodeProvider::Model.new scope: export_scope, model_class: Chouette::StopArea
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(stop_area, code_provider: nil)
        super stop_area
        @code_provider = code_provider
      end

      # TODO: To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          codes: ara_codes,
          parent_id: parent_uuid,
          line_ids: line_uuids,
          collect_children: ara_collect_children?,
          referent_id: referent_uuid
        }
      end

      def ara_collect_children?
        !quay?
      end

      def line_uuids
        lines.map { |line| line.get_objectid&.local_id }
      end

      def parent_uuid
        parent&.get_objectid&.local_id
      end

      def referent_uuid
        referent&.get_objectid&.local_id
      end

      def ara_model
        Ara::File::StopArea.new ara_attributes
      end

      # TODO: To be shared
      def uuid
        get_objectid&.local_id
      end

      # TODO: To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end

  class StopVisits < Part
    def vehicle_journey_at_stops
      sql_query = export_scope.vehicle_journey_at_stops.departure_arrival_base_query
      export_scope.vehicle_journey_at_stops.select('*').from(sql_query)
    end

    def export!
      vehicle_journey_at_stops.includes(:vehicle_journey, stop_point: :stop_area).find_each do |stop_visit|
        target << Decorator.new(stop_visit, day: export_scope.day).ara_model
      end
    end

    class Decorator < SimpleDelegator
      EXPORT_TIME_FORMAT = '%Y-%m-%dT%H:%M:%S%:z'

      def initialize(stop_visit, day:)
        super stop_visit
        @day = day
      end

      def vehicle_journey_at_stop
        __getobj__
      end

      def arrival?
        if vehicle_journey_at_stop.respond_to?(:arrival?)
          vehicle_journey_at_stop.arrival?
        else
          vehicle_journey&.vehicle_journey_at_stops&.last == vehicle_journey_at_stop
        end
      end

      def departure?
        if vehicle_journey_at_stop.respond_to?(:departure?)
          vehicle_journey_at_stop.departure?
        else
          vehicle_journey&.vehicle_journey_at_stops&.first == vehicle_journey_at_stop
        end
      end

      def arrival_time
        super unless departure?
      end

      def departure_time
        super unless arrival?
      end

      def ara_attributes
        {
          id: uuid,
          codes: ara_codes,
          stop_area_id: stop_area_id,
          vehicle_journey_id: vehicle_journey_id,
          passage_order: passage_order,
          schedules: schedules,
          references: references
        }
      end

      def ara_model
        Ara::File::StopVisit.new ara_attributes
      end

      def stop_area_id
        stop_point&.stop_area&.get_objectid&.local_id
      end

      def vehicle_journey_id
        vehicle_journey&.get_objectid&.local_id
      end

      def references
        return unless operator_code

        {
          "OperatorRef": {
            'Type': 'OperatorRef',
            'Code': operator_code
          }
        }
      end

      def operator_code
        return unless company
        return { 'external' => company.registration_number } if company.registration_number

        code = company.codes.first
        return unless code

        { code.code_space.short_name => code.value }
      end

      def company
        vehicle_journey&.company || line&.company
      end
      delegate :line, to: :vehicle_journey, allow_nil: true

      def passage_order
        pos = stop_point&.position
        return '' if pos.nil?

        (pos + 1).to_s
      end

      def schedules
        return unless arrival_time || departure_time

        aimed_schedule = { 'Kind': 'aimed' }
        aimed_schedule[:ArrivalTime] = format_arrival_date(arrival_time) if arrival_time
        aimed_schedule[:DepartureTime] = format_departure_date(departure_time) if departure_time

        [aimed_schedule]
      end

      def uuid
        @uuid ||= SecureRandom.uuid
      end

      def ara_codes
        { external: uuid }
      end

      def format_departure_date(date)
        (date.change(
          year: @day.year,
          month: @day.month,
          day: @day.day
        ) + departure_day_offset.days).strftime(EXPORT_TIME_FORMAT)
      end

      def format_arrival_date(date)
        (date.change(
          year: @day.year,
          month: @day.month,
          day: @day.day
        ) + arrival_day_offset.days).strftime(EXPORT_TIME_FORMAT)
      end
    end
  end

  class Lines < Part
    delegate :lines, to: :export_scope

    def export!
      lines.find_each do |line|
        target << Decorator.new(line, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      @code_provider ||= CodeProvider::Model.new scope: export_scope, model_class: Chouette::Line
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(line, code_provider: nil)
        super line
        @code_provider = code_provider
      end

      # TODO: To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          number: number,
          codes: ara_codes
        }
      end

      def ara_model
        Ara::File::Line.new ara_attributes
      end

      # TODO: To be shared
      def uuid
        get_objectid.local_id
      end

      # TODO: To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end

  class Companies < Part
    delegate :companies, to: :export_scope

    def export!
      companies.find_each do |company|
        target << Decorator.new(company, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      @code_provider ||= CodeProvider::Model.new scope: export_scope, model_class: Chouette::Company
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(company, code_provider: nil)
        super company
        @code_provider = code_provider
      end

      # TODO: To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          codes: ara_codes
        }
      end

      def ara_model
        Ara::File::Operator.new ara_attributes
      end

      # TODO: To be shared
      def uuid
        get_objectid&.local_id
      end

      # TODO: To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end

  class VehicleJourneys < Part
    delegate :vehicle_journeys, to: :export_scope

    def export!
      vehicle_journeys.includes(codes: :code_space, route: :line).find_each do |vehicle_journey|
        target << Decorator.new(vehicle_journey, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      @code_provider ||= CodeProvider::Model.new scope: export_scope, model_class: Chouette::VehicleJourney
    end

    # Creates an Ara::VehicleJourney from a VehicleJourney
    class Decorator < SimpleDelegator
      def initialize(vehicle_journey, code_provider: nil)
        super vehicle_journey
        @code_provider = code_provider
      end

      # TODO: To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: published_journey_name,
          codes: ara_codes,
          line_id: line.get_objectid.local_id,
          direction_type: route.wayback,
          attributes: {
            "VehicleMode": line.transport_mode
          }
        }
      end

      def ara_model
        Ara::File::VehicleJourney.new ara_attributes
      end

      # TODO: To be shared
      def uuid
        get_objectid.local_id
      end

      # TODO: To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end
end
