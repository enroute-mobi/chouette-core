module Chouette::Sync
  module StopArea
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_id_attribute: :id,
          resource_decorator: Decorator,
          model_type: :stop_area,
        }
        options.reverse_merge!(default_options)
        super options
      end

      def quay_updater
        @quay_updater ||= new_updater(resource_type: :quay)
      end

      def stop_place_updater
        @stop_place_updater ||= new_updater(resource_type: :stop_place)
      end

      def update_or_create
        # Order matters, parents "first"
        stop_place_updater.update_or_create
        quay_updater.update_or_create
      end

      def delete_after_update_or_create
        deleter.delete_from(quay_updater, stop_place_updater)
      end

      def after_synchronisation
        [stop_place_updater, quay_updater].each do |updater|
          updater.update_pending_parents
          updater.update_pending_referents
        end
      end

      def counters
        counters = [stop_place_updater, quay_updater, deleter].map(&:counters)
        Counters.sum(counters)
      end

      class Decorator < Chouette::Sync::Netex::Decorator
        # Use type_of_place found in the id when no defined
        CANDIDATE_TYPES = %w{quay monomodalStopPlace multimodalStopPlace}
        def type_of_place_in_id
          CANDIDATE_TYPES.find { |type| id.downcase.include?(type.downcase) } if id
        end

        def type_of_place_in_resource_class
          name_of_class == 'quay' ? 'quay' : 'monomodalStopPlace'
        end

        def type_of_place
          super || type_of_place_in_id || type_of_place_in_resource_class
        end

        # Could be managed into a Netex::Source transformer
        TYPE_MAPPING = {
          'quay' => 'zdep',
          'monomodalStopPlace' => 'zdlp',
          'multimodalStopPlace' => 'lda',
        }.freeze

        def stop_area_type
          TYPE_MAPPING[type_of_place]
        end

        def stop_area_object_version
          version.to_i
        end

        def stop_area_city_name
          postal_address&.town
        end

        def stop_area_parent_ref
          (parent_site_ref || parent_zone_ref)&.ref
        end

        delegate :pending_parent, :pending_referent, to: :updater, allow_nil: true

        def stop_area_parent_id
          return unless stop_area_parent_ref

          @stop_area_parent_id ||= resolve(:stop_area, stop_area_parent_ref).tap do |parent_id|
            pending_parent id, stop_area_parent_ref if parent_id.nil?
          end
        end

        def stop_area_referent_id
          return unless particular?

          pending_referent id, derived_from_object_ref

          nil
        end

        def chouette_transport_mode
          Chouette::TransportMode.new(transport_mode&.underscore, transport_submode&.underscore).code
        end

        def model_attributes # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          {
            name: name,
            area_type: stop_area_type,
            street_name: postal_address&.address_line_1,
            zip_code: postal_address&.post_code,
            postal_region: postal_address&.postal_region,
            city_name: stop_area_city_name,
            object_version: stop_area_object_version,
            latitude: latitude,
            longitude: longitude,
            referent_id: stop_area_referent_id,
            parent_id: stop_area_parent_id,
            status: :confirmed,
            mobility_impaired_accessibility: accessibility.mobility_impaired_access,
            wheelchair_accessibility: accessibility.wheelchair_access,
            step_free_accessibility: accessibility.step_free_access,
            escalator_free_accessibility: accessibility.escalator_free_access,
            lift_free_accessibility: accessibility.lift_free_access,
            audible_signals_availability: accessibility.audible_signals_available,
            visual_signs_availability: accessibility.visual_signs_available,
            accessibility_limitation_description: accessibility.description,
            import_xml: raw_xml,
            transport_mode: chouette_transport_mode
          }.tap do |attributes|
            attributes[:is_referent] = false if particular?
          end
        end
      end
    end

    class Updater < Chouette::Sync::Updater
      # Very Verbose. To be replaced by retry meachanism on not ready resources

      # Decorator can report here when they can find the expect parent
      def pending_parent(resource_id, parent_ref)
        pending_parent_resolver.declare(resource_id, parent_ref)
      end
      def update_pending_parents
        pending_parent_resolver.update
      end

      # Decorator can report here when they can find the expect referent
      def pending_referent(resource_id, referent_ref)
        pending_referent_resolver.declare(resource_id, referent_ref)
      end
      def update_pending_referents
        pending_referent_resolver.update
      end

      def pending_referent_resolver
        @pending_referent_resolver ||= PendingReferentResolver.new(self)
      end
      def pending_parent_resolver
        @pending_parent_resolver ||= PendingResolver.new(self, :parent)
      end

      class PendingResolver

        def initialize(updater, attribute)
          @updater, @attribute = updater, attribute
        end
        attr_reader :attribute, :updater

        delegate :report_invalid_model, :scope, :model_id_attribute, :find_model, :find_models, to: :updater

        def declare(resource_id, reference)
          pendings[resource_id] ||= reference
        end

        def pendings
          @pendings ||= {}
        end

        def update
          pendings.each do |resource_id, reference|
            child = find_model resource_id
            unless child
              Rails.logger.debug { "Can't find child #{model_id_attribute}=#{resource_id} to define #{attribute}=#{reference}" }
              next
            end

            referenced = find_model reference
            unless referenced
              Rails.logger.warn "Can't find reference with #{attribute} #{reference} for StopArea #{resource_id}"
              next
            end

            unless child.update_attribute attribute, referenced
              Rails.logger.error "Invalid child #{child.inspect}"
            end
          end
        end
      end

      # Resolve Stop Area referents
      class PendingReferentResolver < PendingResolver
        def initialize(updater)
          super updater, :referent
        end

        def update
          pending_referents.update_all is_referent: true
          super
        end

        def pending_referents
          find_models pendings.values
        end
      end

    end

    class Deleter < Chouette::Sync::Deleter

      def now
        @now ||= Time.now
      end

      def existing_models(identifiers = nil)
        super(identifiers).where(deleted_at: nil)
      end

      def delete_all(deleted_scope)
        deleted_scope.update_all deleted_at: now
      end

    end

  end
end
