# frozen_string_literal: true

module Query
  class ConnectionLink < Base
    def text(value) # rubocop:disable Metrics/AbcSize
      change_scope(if: value.present?) do |scope|
        base = scope.joins(:departure, :arrival)

        departure_table = base.arel.join_sources[-2].left
        arrival_table = base.arel.join_sources[-1].left

        name = scope.arel_table[:name].matches("%#{value}%")
        departure_name = departure_table[:name].matches("%#{value}%")
        arrival_name = arrival_table[:name].matches("%#{value}%")

        base.where(name.or(departure_name).or(arrival_name))
      end
    end
  end
end
