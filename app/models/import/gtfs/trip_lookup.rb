# frozen_string_literal: true

module Import
  class Gtfs
    # Add specific logic to the lookup to help GTFS Trips import
    class TripLookup
      def initialize(referential: nil, lookup: nil, shape_provider: nil, code_space: nil)
        @referential = referential
        @lookup = lookup
        @shape_provider = shape_provider
        @code_space = code_space
      end

      attr_reader :referential, :lookup, :shape_provider, :code_space

      def journey_patterns
        @journey_patterns ||= JourneyPatterns.new(referential:, lookup:)
      end

      class JourneyPatterns
        attr_reader :referential, :lookup

        def initialize(referential: nil, lookup: nil)
          @referential = referential
          @lookup = lookup
        end

        def register(journey_pattern, signature:)
          Rails.logger.debug { "Register #{journey_pattern.id} with signature #{signature.inspect}" }
          journey_pattern_ids_by_signature[signature] = journey_pattern.id
        end

        def find_id_by(signature:)
          Rails.logger.debug { "Find Journey Pattern id by signature #{signature.inspect}" }
          journey_pattern_ids_by_signature[signature]
        end

        def journey_pattern_ids_by_signature
          @journey_pattern_ids_by_signature ||= {}
        end

        def journey_patterns_by_signature
          @journey_patterns_by_signature ||= {}
        end

        def find_by(signature:)
          Rails.logger.debug { "Find Journey Pattern by signature #{signature.inspect}" }
          journey_patterns_by_signature[signature] ||=
            begin
              journey_pattern_id = find_id_by(signature: signature)
              return nil unless journey_pattern_id

              referential.journey_patterns.includes(:stop_points).find(journey_pattern_id)
            end
        end
      end

      def time_tables
        @time_tables ||= Timetables.new(referential:, lookup:)
      end

      class Timetables
        attr_reader :referential, :lookup

        def initialize(referential: nil, lookup: nil)
          @referential = referential
          @lookup = lookup
        end

        def find_id(code, starting_day_offset: 0)
          return lookup.time_tables.find_id(code) if starting_day_offset.zero?

          find_shifted_id code, starting_day_offset: starting_day_offset
        end

        def find_shifted_id(code, starting_day_offset:)
          shifted_timetables[[code, starting_day_offset]] ||= create_shifted(code, starting_day_offset:).id
        end

        def create_shifted(code, starting_day_offset:)
          original = lookup.time_tables.find(code)

          shifted_timetable = original.to_timetable
          shifted_timetable.shift starting_day_offset

          shifted = referential.time_tables.build comment: code
          shifted.apply shifted_timetable
          shifted.shortcuts_update
          shifted.skip_save_shortcuts = true
          shifted.save!

          shifted
        end

        def shifted_timetables
          @shifted_timetables ||= {}
        end
      end

      def accessibility_assessments
        @accessibility_assessments ||= AccessibilityAssessments.new(shape_provider:, code_space:)
      end

      class AccessibilityAssessments
        def initialize(shape_provider: nil, code_space: nil)
          @shape_provider = shape_provider
          @code_space = code_space
        end

        attr_reader :shape_provider, :code_space

        def find_by(wheelchair_accessible:)
          case wheelchair_accessible
          when '1'
            @accessibility_assessment_wheelchair_accessible ||=
              shape_provider.accessibility_assessments.first_or_create_by_code(code_space,
                                                                               'gtfs-wheelchair-accessible') do |a|
                a.name = 'GTFS - Mobility reduced passenger suitable'
                a.wheelchair_accessibility = 'yes'
              end
          when '2'
            @accessibility_assessment_wheelchair_not_accessible ||=
              shape_provider.accessibility_assessments.first_or_create_by_code(code_space,
                                                                               'gtfs-wheelchair-not-accessible') do |a|
                a.name = 'GTFS - Mobility reduced passenger not suitable'
                a.wheelchair_accessibility = 'no'
              end
          end
        end
      end

      def service_facility_sets
        @service_facility_sets ||= ServiceFacilitySets.new(shape_provider:, code_space:)
      end

      class ServiceFacilitySets
        def initialize(shape_provider: nil, code_space: nil)
          @shape_provider = shape_provider
          @code_space = code_space
        end

        attr_reader :shape_provider, :code_space

        def find_by(bikes_allowed:)
          case bikes_allowed
          when '1'
            @service_facility_set_cycles_allowed ||= shape_provider.service_facility_sets.first_or_create_by_code(
              code_space, 'gtfs-bikes-allowed'
            ) do |s|
              s.name = 'GTFS - Bikes allowed'
              s.associated_services = ['luggage_carriage/cycles_allowed']
            end
          when '2'
            @service_facility_set_no_cycle ||= shape_provider.service_facility_sets.first_or_create_by_code(code_space,
                                                                                                            'gtfs-bikes-not-allowed') do |s|
              s.name = 'GTFS - Bikes not allowed'
              s.associated_services = ['luggage_carriage/no_cycles']
            end
          end
        end
      end
    end
  end
end
