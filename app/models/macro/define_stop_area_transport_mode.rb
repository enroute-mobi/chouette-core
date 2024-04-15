# frozen_string_literal: true

module Macro
  class DefineStopAreaTransportMode < Macro::Base
    class Run < Macro::Base::Run
      def run
        candidate_stop_areas.find_each do |stop_area|
          Updater.new(stop_area, macro_messages).update
        end
      end

      class Updater
        def initialize(stop_area, messages)
          @stop_area = stop_area
          @messages = messages
        end

        def update
          if stop_area.update transport_mode: chouette_transport_mode.code
            create_message
          else
            create_message criticity: 'error', message_key: 'error'
          end
        end

        def chouette_transport_mode
          @chouette_transport_mode ||=
            ::Chouette::TransportMode.new(line_transport_mode, line_transport_submode)
        end

        delegate :line_transport_mode, to: :stop_area

        def line_transport_submode
          return nil if stop_area.line_transport_submode == 'undefined'

          stop_area.line_transport_submode
        end

        attr_reader :stop_area, :messages

        def create_message(attributes = {})
          return unless messages

          attributes.merge!(
            message_attributes: {
              name: stop_area.name,
              transport_mode: chouette_transport_mode.human_name
            },
            source: stop_area
          )
          messages.create!(attributes)
        end
      end

      def candidate_stop_areas
        scope
          .stop_areas
          .select(
            'public.stop_areas.*',
            'lines.transport_mode AS line_transport_mode',
            'lines.transport_submode AS line_transport_submode'
          )
          .joins(routes: :line)
          .where(id: candidate_stop_area_ids)
          .distinct
      end

      def candidate_stop_area_ids
        Chouette::StopArea
          .select(:id)
          .from("(#{base_query.to_sql}) stop_area_ids")
          .group(:id)
          .having('count(*) = 1')
      end

      def base_query
        scope
          .stop_areas
          .where(transport_mode: nil)
          .where.not(routes: { lines: { transport_mode: nil } })
          .distinct
          .select(
            'public.stop_areas.id',
            'public.lines.transport_mode AS line_transport_mode',
            'public.lines.transport_submode AS line_transport_submode'
          )
          .joins(routes: :line)
      end
    end
  end
end
