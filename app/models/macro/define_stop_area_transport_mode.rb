# frozen_string_literal: true

module Macro
  class DefineStopAreaTransportMode < Macro::Base
    class Run < Macro::Base::Run
      def run
        candidate_stop_areas.find_each do |stop_area|
          Updater.new(self, stop_area).update
        end
      end

      class Updater
        def initialize(macro_run, stop_area)
          @macro_run = macro_run
          @stop_area = stop_area
        end
        attr_reader :macro_run, :stop_area

        delegate :messages, to: :macro_run

        def update
          success = stop_area.update transport_mode: chouette_transport_mode.code

          messages.create(source: stop_area, transport_mode: chouette_transport_mode.human_name) do |message|
            message.error! unless success
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
          .where.not(::Chouette::Line.quoted_table_name => { transport_mode: nil })
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
