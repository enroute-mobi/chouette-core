# frozen_string_literal: true

module Query
  class StopAreaRoutingConstraint < Base
    def text(value) # rubocop:disable Metrics/AbcSize
      change_scope(if: value.present?) do |scope|
        base = scope.joins(:from, :to)

        from_table = base.arel.join_sources[-2].left
        to_table = base.arel.join_sources[-1].left

        from_name = from_table[:name].matches("%#{value}%")
        to_name = to_table[:name].matches("%#{value}%")

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
