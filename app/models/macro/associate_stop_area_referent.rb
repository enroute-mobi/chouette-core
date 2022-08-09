module Macro
  class AssociateStopAreaReferent < Base
    class Run < Macro::Base::Run
      def run
        ::Macro::Message.transaction do
          raw_associations.each do |association|
            particular_id = association["particular_id"]
            closest_referent_id = association["closest_referent_id"]

            stop_area = stop_areas.find(particular_id)
            if stop_area.update!(referent_id: closest_referent_id)
              self.macro_messages.create(
                criticity: "info",
                message_attributes: { name: stop_area.name },
                source: stop_area,
              )
            end
          end
        end
      end

      def stop_areas
        scope.stop_areas
      end

      def selected_attributes
        position_as = "ST_SetSRID(ST_Point(longitude, latitude), 4326) as position"
        [ :id, :area_type, :compass_bearing, position_as ]
      end

      def particulars
        stop_areas.where(is_referent: false, referent_id: nil).select(*selected_attributes)
      end

      def referents
        CustomScope.new(self).scope(macro_list_run.base_scope).stop_areas.where(is_referent: true).select(*selected_attributes)
      end

      def max_srid_distance
        0.0001
      end

      def max_bearing_distance
        7.5
      end

      def raw_associations
         query = <<~SQL
           SELECT particulars.id AS particular_id, closest_referent.id AS closest_referent_id
           FROM (#{particulars.to_sql}) AS particulars
           CROSS JOIN LATERAL(
             SELECT referents.id
             FROM (#{referents.to_sql}) AS referents
             WHERE referents.area_type = particulars.area_type
               AND referents.compass_bearing
                 BETWEEN particulars.compass_bearing - #{max_bearing_distance}
                  AND particulars.compass_bearing + #{max_bearing_distance}
               AND st_dwithin(particulars.position, referents.position, #{max_srid_distance})
             ORDER BY
               particulars.position <-> referents.position,
               abs(referents.compass_bearing - particulars.compass_bearing)
            LIMIT 1
          ) AS closest_referent;
         SQL

         PostgreSQLCursor::Cursor.new(query)
      end
    end
  end
end
