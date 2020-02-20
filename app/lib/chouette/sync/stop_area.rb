module Chouette::Sync
  module StopArea
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_id_attribute: :id,
          resource_decorator: Decorator,
          model_type: :stop_area,
          model_id_attribute: :registration_number
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

      # Decorator can report here when they can find the expect parent
      def pending_parent(resource_id, parent_ref)
        pending_parents[resource_id] ||= parent_ref
      end

      def pending_parents
        @pending_parents ||= {}
      end

      def delete_after_update_or_create
        deleter.delete_from(quay_updater, stop_place_updater)

        pending_parents.each do |resource_id, parent_ref|
          # TODO
          # could be processed in batch
        end
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        # Use type_of_place found in the id when no defined
        CANDIDATE_TYPES = %{quay monomodalStopPlace multimodalStopPlace}
        def type_of_place_in_id
          CANDIDATE_TYPES.find { |type| id.downcase.include?(type.downcase) }
        end

        def type_of_place
          super || type_of_place_in_id
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

        def stop_area_is_referent
          derived_from_object_ref.present?
        end

        def stop_area_parent_ref
          parent_site_ref || parent_zone_ref
        end

        def stop_area_parent_id
          @stop_area_parent_id ||=
            begin
              resolve(:stop_area, stop_area_parent_ref).tap do |parent_id|
                if parent_id.present? and batch&.updater
                  batch.updater.pending_parent id, stop_area_parent_ref
                end
              end
            end
        end

        def stop_area_referent_id
          return unless stop_area_is_referent
          resolve :stop_area, derived_from_object_ref
        end

        def stop_area_provider_id
          # Reflex "FR1-ARRET_AUTO" value is removed by Netex::Source transformers
          resolve :stop_area_provider, data_source_ref
        end

        # TODO How to manage
        # confirmed_at
        # created_at
        # deleted_at
        #
        # /!\ nil values can be ignored
        def model_attributes
          {
            name: name,
            postal_region: postal_address&.postal_region,
            city_name: stop_area_city_name,
            object_version: stop_area_object_version,
            is_referent: stop_area_is_referent,
            latitude: latitude,
            longitude: longitude,
            import_xml: raw_xml,
            parent_id: stop_area_parent_id
          }
        end

      end

    end

  end
end
