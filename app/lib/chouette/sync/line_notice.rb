module Chouette::Sync
  module LineNotice
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :notice,
          resource_id_attribute: :id,
          model_type: :line_notice,
          resource_decorator: Decorator
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Netex::Decorator

        def line_notice_title
          name
        end

        def line_notice_content
          text
        end

        def model_attributes
          {
            name: line_notice_title,
            content: line_notice_content,
            import_xml: raw_xml
          }
        end

      end

    end

    class Updater < Chouette::Sync::Updater
      def resources
        @resources ||= source.notices.lazy.select { |n| n.type_of_notice_ref&.ref.in?(%w[Line LineNotice]) }
      end
    end
  end
end
