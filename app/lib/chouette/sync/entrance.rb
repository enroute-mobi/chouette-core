module Chouette::Sync
  module Entrance
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :stop_place_entrance,
          resource_id_attribute: :id,
          resource_decorator: Decorator,
          model_type: :entrance,
          model_id_attribute: :codes,
        }
        options.reverse_merge!(default_options)

        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        delegate :source, to: :updater

        def stop_area_id
          resolve :stop_area, stop_place_ref
        end

        def stop_area_provider_id
          resolve :stop_area_provider, data_source_ref
        end

        def position
          "#{longitude} #{latitude}"
        end

        def address
          postal_address&.address_line_1
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
            short_name: short_name,
            description: description,
            position_input: position,
            address: address,
            zip_code: zip_code,
            city_name: city_name,
            country: country,
            entrance_type: entrance_type,
            entry_flag: is_entry,
            exit_flag: is_exit,
            import_xml: raw_xml,
            stop_area_id: stop_area_id,
            stop_area_provider_id: stop_area_provider_id,
          }
        end

        private

        def stop_place_ref
          mapping_entrance_stop_place[id]
        end

        def mapping_entrance_stop_place
          unless @mapping_entrance_stop_place.present?
            @mapping_entrance_stop_place = {}
            resources.each do |resource|
              next unless resource.is_a? ::Netex::StopPlace

              resource&.entrances.each do |entrance|
                @mapping_entrance_stop_place[entrance.ref] = resource&.id
              end
            end
          end
          @mapping_entrance_stop_place
        end

        def data_source_ref
          resources.find{ |resource| resource.is_a? ::Netex::StopPlace }.data_source_ref
        end

        def resources
          source.resources
        end
      end
    end
  end
end