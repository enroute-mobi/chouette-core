module Chouette::Sync
  module StopAreaGroup
    class Netex < Chouette::Sync::Base
      def initialize(options = {})
        default_options = {
          resource_type: :group_of_stop_place,
          resource_id_attribute: :id,
          resource_decorator: Decorator,
          model_type: :stop_area_group,
          model_id_attribute: :codes
        }
        options.reverse_merge!(default_options)

        super options
      end

      class Decorator < Chouette::Sync::Netex::Decorator
        delegate :source, to: :updater

        def stop_area_ids
          @stop_area_ids ||= resolve :stop_area, members.map(&:ref)
        end

        def model_attributes # rubocop:disable Metrics/MethodLength
          {
            name: name,
            short_name: short_name,
            description: description,
            stop_area_ids: stop_area_ids
          }
        end
      end
    end
  end
end
