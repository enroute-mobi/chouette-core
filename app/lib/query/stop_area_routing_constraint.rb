# frozen_string_literal: true

module Query
  class StopAreaRoutingConstraint < Base
    module CustomJoins
      extend ::Query::Base::CustomJoins

      define :from, 'INNER JOIN "public"."stop_areas" "from" ON "from"."id" = "public"."stop_area_routing_constraints"."from_id"' # rubocop:disable Layout/LineLength
      define :to, 'INNER JOIN "public"."stop_areas" "to" ON "to"."id" = "public"."stop_area_routing_constraints"."to_id"' # rubocop:disable Layout/LineLength
    end

    def text(value) # rubocop:disable Metrics/AbcSize
      change_scope(if: value.present?) do |scope|
        base = scope.joins(:from, :to)

        from_name = Chouette::StopArea.arel_table.alias('from')[:name].matches("%#{value}%")
        to_name = Chouette::StopArea.arel_table.alias('to')[:name].matches("%#{value}%")

        base.where(from_name.or(to_name))
      end
    end

    def both_way(value)
      change_scope(if: value.present?) do |scope|
        scope.where(both_way: value == '1')
      end
    end
  end
end
