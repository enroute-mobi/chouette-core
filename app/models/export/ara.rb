class Export::Ara < Export::Base
  include LocalExportSupport

  # FIXME Should be shared
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :exported_lines, default_value: 'all_line_ids',
         enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :duration # Ignored by this export .. but required by Export::Scope builder

  skip_empty_exports

  def content_type
    'application/csv'
  end

  def file_extension
    "csv"
  end

  # TODO Should be shared
  def export_file
    @export_file ||= Tempfile.new(["export#{id}",".#{file_extension}"])
  end

  def target
    @target ||= ::Ara::File.new export_file
  end
  attr_writer :target

  def period
    @period ||=
      begin
        today = Time.zone.today
        today..today+5
      end
  end

  def generate_export_file
    parts = [ Stops, Lines, VehicleJourneys ]

    period.each do |day|
      # For each day, a scope selects models to be exported
      daily_scope = DailyScope.new export_scope, day

      target.model_name(day) do |model_name|
        # For each day, each kind of model is exported
        parts.each do |part|
          part.new(export_scope: daily_scope, target: model_name).export
        end

        # TODO
        # VehicleJourneyAtStops.new(export_scope: daily_scope, target: model_name).export
      end
    end

    target.close

    export_file.close
    export_file
  end

  # Use Export::Scope::Scheduled which scopes all models according to vehicle_journeys
  class DailyScope < Export::Scope::Scheduled
    def initialize(export_scope, day)
      super export_scope
      @day = day
    end

    attr_reader :day

    def vehicle_journeys
      current_scope.vehicle_journeys.scheduled_on(day)
    end
  end

  # TODO To be shared
  module CodeProvider
    # Manage all CodeSpace for a Model class (StopArea, VehicleJourney, ...)
    class Model
      def initialize(scope: , model_class:)
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
            [ code_provider.short_name, unique_code ] if unique_code
          end.compact.to_h
        end

        # Use registration_number as legacy mode
        if model.respond_to?(:registration_number) &&
           !unique_codes.key?(registration_number_provider.short_name)

          unique_code = registration_number_provider.unique_code(model)
          unique_codes[registration_number_provider.short_name] = unique_code if unique_code
        end

        unique_codes
      end

      # Provide (unique) value from registration provider
      def registration_number_provider
        @registration_number_provider ||=
          CodeProvider::RegistrationNumber.new scope: scope,
                                               model_class: model_class
      end

      # Provide (unique) value for each Copde Space
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
            [ code.code_space.short_name, code.value ]
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
        "external"
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
        @duplicated_registration_numbers ||=
          SortedSet.new(models.group(:registration_number).having("count(#{model_class.model_name.plural}.id) > 1").pluck(:registration_number))
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
          SortedSet.new(model_codes.select(:value, :resource_id).group(:value).having("count(resource_id) > 1").pluck(:value))
      end
    end
  end

  class Part
    attr_reader :export_scope, :target

    def initialize(export_scope:, target:)
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

  class Stops < Part
    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.includes(codes: :code_space).find_each do |stop_area|
        target << Decorator.new(stop_area, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      CodeProvider::Model.new scope: export_scope, model_class: Chouette::StopArea
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(stop_area, code_provider: nil)
        super stop_area
        @code_provider = code_provider
      end

      # TODO To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          objectids: ara_codes,
        }
      end

      def ara_model
        Ara::StopArea.new ara_attributes
      end

      # TODO To be shared
      def uuid
        get_objectid.local_id
      end

      # TODO To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
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
      CodeProvider::Model.new scope: export_scope, model_class: Chouette::Line
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(line, code_provider: nil)
        super line
        @code_provider = code_provider
      end

      # TODO To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          objectids: ara_codes,
        }
      end

      def ara_model
        Ara::Line.new ara_attributes
      end

      # TODO To be shared
      def uuid
        get_objectid.local_id
      end

      # TODO To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end

  class VehicleJourneys < Part
    delegate :vehicle_journeys, to: :export_scope

    def export!
      vehicle_journeys.includes(codes: :code_space).find_each do |vehicle_journey|
        target << Decorator.new(vehicle_journey, code_provider: code_provider).ara_model
      end
    end

    def code_provider
      CodeProvider::Model.new scope: export_scope, model_class: Chouette::VehicleJourney
    end

    # Creates an Ara::StopArea from a StopArea
    class Decorator < SimpleDelegator
      def initialize(vehicle_journey, code_provider: nil)
        super vehicle_journey
        @code_provider = code_provider
      end

      # TODO To be shared
      def code_provider
        @code_provider ||= CodeProvider::Model.null
      end

      def ara_attributes
        {
          id: uuid,
          name: published_journey_name,
          objectids: ara_codes,
        }
      end

      def ara_model
        Ara::VehicleJourney.new ara_attributes
      end

      # TODO To be shared
      def uuid
        get_objectid.local_id
      end

      # TODO To be shared
      def ara_codes
        code_provider.unique_codes __getobj__
      end
    end
  end
end