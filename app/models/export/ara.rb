class Export::Ara < Export::Base
  include LocalExportSupport

  # FIXME Should be shared
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :exported_lines, default_value: 'all_line_ids',
         enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :duration # Ignored

  skip_empty_exports

  def target
    @target ||= ::Ara::File.new export_file
  end
  attr_writer :target

  def content_type
    'application/csv'
  end

  def file_extension
    "csv"
  end

  def export_file
    @export_file ||= Tempfile.new(["export#{id}",".#{file_extension}"])
  end

  def period
    Date.today..Date.today+5
  end

  def generate_export_file
    period.each do |day|
      # For each day, a scope selects models to be exported
      daily_scope = DailyScope.new export_scope, day

      target.model_name(day) do |model_name|
        Stops.new(export_scope: daily_scope, target: model_name).export

        # TODO
        # Lines.new(export_scope: daily_scope, target: model_name).export
        # VehicleJourneys.new(export_scope: daily_scope, target: model_name).export
        # VehicleJourneyAtStops.new(export_scope: daily_scope, target: model_name).export
      end
    end

    target.close

    export_file.close
    export_file
  end

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
    # Manage all CodeSpace for a Resource class
    class Resource
      def initialize(scope: , resource_class:)
        @scope = scope
        @resource_class = resource_class
      end

      def unique_codes(resource)
        code_spaces = resource.codes.map(&:code_space).uniq

        code_spaces.map do |code_space|
          code_provider = code_providers[code_space]
          [ code_provider.short_name, code_provider.unique_code(resource) ]
        end.to_h
      end

      def code_providers
        @code_providers ||= Hash.new do |h, code_space|
          h[code_space] =
            CodeProvider::CodeSpace.new scope: export_scope,
                                        code_space: code_space,
                                        resource_class: resource_class
        end
      end

      # Returns original resource codes
      def self.null
        @null ||= Null.new
      end

      class Null
        def unique_codes(resource)
          resource.codes.map do |code|
            [ code.code_space.short_name, code.value ]
          end.to_h
        end
      end
    end

    # Manage a single CodeSpace for a Resource class
    # TODO To be used in Export::Gtfs
    class CodeSpace

      def initialize(scope:, code_space:, resource_class:)
        @scope = scope
        @code_space = code_space
        @resource_class = resource_class
      end

      delegate :short_name, to: :code_space

      def unique_code(resource)
        candidates = candidate_codes(resource)
        return nil unless candidates.one?

        candidate_value = candidates.first.value
        return nil if duplicated?(candidate_value)

        candidate_value
      end

      def candidate_codes(resource)
        resource.codes.select { |code| code.code_space_id == code_space.id }
      end

      def duplicated?(code_value)
        duplicated_code_values.include? code_value
      end

      def resource_collection
        resource_class.model_name.plural
      end

      def resources
        scope.send resource_collection
      end

      def resource_codes
        codes.where(code_space: code_space, resource: resources)
      end

      def codes
        # FIXME
        resource_class == Chouette::VehicleJourney ?
          scope.referential_codes : scope.codes
      end

      def duplicated_code_values
        @duplicated_code_values ||=
          SortedSet.new(resource_codes.select(:value, :resource_id).group(:value).having("count(resource_id) > 1").pluck(:value))
      end
    end
  end

  class Part
    attr_reader :export_scope, :target

    def initialize(export_scope:, target:)
      @export_scope = export_scope
      @target = target
      # options.each { |k,v| send "#{k}=", v }
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
        target << Decorator.new(stop_area, code_provider: code_provider).ara_resource
      end
    end

    def code_provider
      CodeProvider::Resource.new scope: export_scope, resource_class: Chouette::StopArea
    end

    class Decorator < SimpleDelegator

      def initialize(stop_area, code_provider: nil)
        super stop_area
        @code_provider = code_provider
      end

      def ara_attributes
        {
          id: uuid,
          name: name,
          objectids: ara_codes,
        }
      end

      def ara_resource
        Ara::StopArea.new ara_attributes
      end

      def uuid
        get_objectid.local_id
      end

      def code_provider
        @code_provider ||= CodeProvider::Resource.null
      end

      def ara_codes
        code_provider.unique_codes __getobj__
      end

    end

  end

end
