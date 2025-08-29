# frozen_string_literal: true

module Export
  module Setup
    module Scope
      class PeriodSelector < ApplicationStoreModel
        class All < PeriodSelector
        end

        class Duration < PeriodSelector # TODO: Gtfs and Netex only
          attribute :day_count, :integer

          validates :day_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
        end

        class Static < PeriodSelector # TODO: Gtfs and Netex only
          attribute :from, :date
          attribute :to, :date

          validates :from, :to, presence: true
          validate :validate_from_to_range

          private

          def validate_from_to_range
            return unless from && to
            return unless from >= to

            errors.add(:from, :invalid)
            errors.add(:to, :invalid)
          end
        end
      end

      class LineSelector < ApplicationStoreModel
        class Lines < LineSelector
          attribute :line_ids, IntegerArrayType.new

          validates :line_ids, presence: true
        end

        class Companies < LineSelector
          attribute :company_ids, IntegerArrayType.new

          validates :company_ids, presence: true
        end

        class Networks < LineSelector # TODO: unused for now
          attribute :network_ids, IntegerArrayType.new

          validates :network_ids, presence: true
        end

        class LineProviders < LineSelector
          attribute :line_provider_ids, IntegerArrayType.new

          validates :line_provider_ids, presence: true
        end

        class All < LineSelector
        end
      end

      class StopAreas < ApplicationStoreModel
        class None < StopAreas # TODO: unused for now
        end

        class Scheduled < StopAreas
          attribute :prefer_referent_stop_areas, :boolean, default: false # TODO: Gtfs only
          attribute :ignore_parent_stop_areas, :boolean, default: false # TODO: Gtfs only
          attribute :ignore_referent_stop_areas, :boolean, default: false # TODO: Netex only
        end

        class All < Scheduled # TODO: unused for now
          attribute :ignore_disabled_stop_areas, :boolean # TODO: unused for now
        end
      end

      class Lines < ApplicationStoreModel
        class None < Lines # TODO: unused for now
        end

        class Scheduled < Lines
          attribute :prefer_referent_lines, :boolean, default: false # TODO: Gtfs and Netex only
          attribute :prefer_referent_companies, :boolean, default: false # TODO: Gtfs only
        end

        class All < Scheduled # TODO: unused for now
        end
      end

      class Shapes < ApplicationStoreModel # TODO: unused for now
      end

      class PointOfInterests < ApplicationStoreModel # TODO: unused for now
      end

      class VehicleJourneys < ApplicationStoreModel
        attribute :period, PeriodSelector.one_of_descendants.to_type, default: -> { PeriodSelector::All.new }
        attribute :included_lines, LineSelector.one_of_descendants.to_type, default: -> { LineSelector::All.new }
        attribute :excluded_lines, LineSelector.one_of_descendants.to_type, default: nil

        validates :period, :included_lines, store_model: true
        validates :excluded_lines, store_model: true, if: ->(r) { r.excluded_lines.present? }
      end

      class Setup < ApplicationStoreModel
        attribute :stop_areas, StopAreas.one_of_descendants.to_type, default: -> { StopAreas::All.new }
        attribute :lines, Lines.one_of_descendants.to_type, default: -> { Lines::All.new }
        attribute :shapes, Shapes.to_type, default: -> { Shapes.new }
        attribute :point_of_interests, PointOfInterests.to_type, default: -> { PointOfInterests.new }

        validates :stop_areas, :lines, :shapes, :point_of_interests, store_model: true
      end

      class AbstractReferential < Setup
        attribute :vehicle_journeys, VehicleJourneys.to_type, default: -> { VehicleJourneys.new }

        validates :vehicle_journeys, store_model: true
      end

      class Referential < AbstractReferential
      end

      class PublishedReferential < AbstractReferential
      end

      class Workbench < Setup # TODO: unused for now
        attribute :workbench_id, :integer
      end

      class Workgroup < Setup # TODO: unused for now
        attribute :workgroup_id, :integer # TODO why? we know in which workgroup we are
      end
    end

    class Base < ApplicationStoreModel
      self.abstract_class = true

      attribute :type, :string # see https://enroute.atlassian.net/browse/CHOUETTE-4855?focusedCommentId=57626
      attribute :scope_setup, Scope::Setup.one_of_descendants.to_type
      attribute :code_space_id, :integer # TODO: Gtfs and Netex only

      validates :scope_setup, store_model: true
      # rubocop:disable Layout/FirstHashElementIndentation
      validates :code_space_id, inclusion: {
                                  in: ->(r) { r.parent.workgroup.code_spaces.pluck(:id) },
                                  allow_blank: true
                                }
      # rubocop:enable Layout/FirstHashElementIndentation
      validate :validate_scope_setup_class

      def candidate_scope_setup_classes
        [].tap do |result|
          result << Scope::Referential if parent.is_a?(::Export::Base)
          result << Scope::PublishedReferential if parent.is_a?(::PublicationSetup)
        end
      end

      def stateful?
        true
      end

      private

      def validate_scope_setup_class
        return if candidate_scope_setup_classes.any? { |k| scope_setup.is_a?(k) }

        errors.add(:scope_setup, :invalid)
      end
    end

    class Gtfs < Base
      attribute :ignore_extended_route_types, :boolean, default: false
      attribute :stop_sequence_from_one, :boolean, default: false
    end

    class Netex < Base
      extend Enumerize

      attribute :profile, :string, default: 'none'
      attribute :profile_options, default: -> { {} }
      attribute :participant_ref, :string, default: 'enRoute'
      attribute :skip_line_resources, :boolean, default: false
      attribute :skip_stop_area_resources, :boolean, default: false

      # TODO: Remove deprecated idfm/full. See @CHOUETTE-4619
      enumerize :profile, in: %w[none french european idfm/iboo idfm/icar idfm/publication idfm/full]
      validates :profile, presence: true
    end

    class Ara < Base
      attribute :include_stop_visits, :boolean, default: false

      def stateful?
        false
      end
    end
  end
end
