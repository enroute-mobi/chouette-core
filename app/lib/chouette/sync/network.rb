module Chouette::Sync
  module Network
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :network,
          resource_id_attribute: :id,
          model_type: :network,
          resource_decorator: Decorator
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Netex::Decorator

        def model_attributes
          {
            name: name,
            import_xml: raw_xml
          }
        end

      end

    end

  end
end
