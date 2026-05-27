module Chouette::Sync
  module Company
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :operator,
          resource_id_attribute: :id,
          model_type: :company,
          resource_decorator: Decorator
        }
        options.reverse_merge!(default_options)
        super options
      end

      def after_synchronisation
        updater.update_pending_referents
      end

      class Decorator < Chouette::Sync::Netex::Decorator

        delegate :house_number, :address_line_1, :address_line_2, :street, :town,
                 :post_code, :post_code_extension, :postal_region, to: :address, allow_nil: true

        delegate :email, :phone, :url, to: :contact_details, prefix: :default_contact, allow_nil: true

        def company_default_contact_name
          contact_details&.contact_person
        end

        def company_default_contact_more
          contact_details&.further_details
        end

        def company_referent_id
          return unless particular?

          pending_referent id, derived_from_object_ref

          nil
        end

        def model_attributes
          {
            name: name,
            time_zone: "Europe/Paris",

            house_number: house_number,
            address_line_1: address_line_1,
            address_line_2: address_line_2,
            street: street,
            town: town,
            postcode: post_code,
            postcode_extension: post_code_extension,

            default_contact_name: company_default_contact_name,
            default_contact_phone: default_contact_phone,
            default_contact_email: default_contact_email,
            default_contact_url: default_contact_url,
            default_contact_more: company_default_contact_more,
            referent_id: company_referent_id,
            import_xml: raw_xml
          }.tap do |attributes|
            attributes[:is_referent] = false if particular?
          end
        end

      end

    end

  end
end
