module Chouette::Sync
  module Entrance
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :stop_place_entrance,
          resource_id_attribute: :id,
          resource_decorator: Decorator,
          model_type: :entrance,
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        delegate :source, to: :updater

        def stop_area_id
          resolve :stop_area, stop_place_ref_id
        end

        def stop_area_provider_id
          ::Chouette::StopArea.find_by_id(stop_area_id)&.stop_area_provider_id
        end

        def position
          "POINT(#{longitude} #{latitude})"
        end

        def address
          [postal_address&.house_number, postal_address&.street].compact.join(" ")
        end

        def zip_code
          postal_address&.post_code
        end

        def city_name
          postal_address&.town
        end

        def country
          postal_address&.country_name
        end

        def model_attributes
          {
            name: name,
            entry_flag: is_entry,
            exit_flag: is_exit,
            external_flag: is_external,
            height: height,
            width: width,
            address: address,
            zip_code: zip_code,
            city_name: city_name,
            country: country,
            position: position,
            entrance_type: entrance_type,
            stop_area_id: stop_area_id,
            stop_area_provider_id: stop_area_provider_id,
          }
        end

        private

        def stop_place_ref_id
          source.resources.find{ |resource| resource&.entrances&.map(&:ref).include? id }&.id
        end

      end
    end
  end
end