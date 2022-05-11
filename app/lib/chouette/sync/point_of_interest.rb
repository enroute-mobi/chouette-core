module Chouette::Sync
  module PointOfInterest
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :point_of_interest,
          resource_id_attribute: :id,
          model_type: :point_of_interest,
          resource_decorator: Decorator,
          model_id_attribute: :codes,
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        delegate :contact_details, to: :operating_organisation_view

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

        def email
          contact_details&.email
        end

        def phone
          contact_details&.phone
        end

        def netex_shape_provider_id
          resolve :shape_provider, data_source_ref
        end

        def netex_point_of_interest_category_id
          ::PointOfInterest::Category.find_by(
            shape_provider_id: netex_shape_provider_id,
            name: classifications.first.try(:name)
          )&.id
        end

        def model_attributes
          {
            name: name,
            url: url,
            position_input: position,
            address: address,
            zip_code: zip_code,
            city_name: city_name,
            country: country,
            raw_import_attributes: { content: raw_xml },
            phone: phone,
            email: email,
            point_of_interest_category_id: netex_point_of_interest_category_id
          }.tap do |attributes|
            attributes[:shape_provider_id] = netex_shape_provider_id if netex_shape_provider_id
          end
        end
      end
    end
  end
end
