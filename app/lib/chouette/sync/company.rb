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

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        def model_attributes
          {
            name: name,
            time_zone: "Europe/Paris",
            import_xml: raw_xml
          }
        end

      end

    end

  end
end
