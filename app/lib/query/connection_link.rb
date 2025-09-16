# frozen_string_literal: true

module Query
  class ConnectionLink < Base
    module CustomJoins
      extend ::Query::Base::CustomJoins

      define :departure, 'INNER JOIN "public"."stop_areas" "departure" ON "departure"."id" = "public"."connection_links"."departure_id"' # rubocop:disable Layout/LineLength
      define :arrival, 'INNER JOIN "public"."stop_areas" "arrival" ON "arrival"."id" = "public"."connection_links"."arrival_id"' # rubocop:disable Layout/LineLength
    end

    def text(value) # rubocop:disable Metrics/AbcSize
      change_scope(if: value.present?) do |scope|
        base = scope.joins(:departure, :arrival)

        name = scope.arel_table[:name].matches("%#{value}%")
        departure_name = Chouette::StopArea.arel_table.alias('departure')[:name].matches("%#{value}%")
        arrival_name = Chouette::StopArea.arel_table.alias('arrival')[:name].matches("%#{value}%")

        base.where(name.or(departure_name).or(arrival_name))
      end
    end
  end
end
