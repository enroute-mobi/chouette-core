# frozen_string_literal: true

module Scope
  class FromLines < Base
    collection :line_groups do
      current_collection.where(
        id: ::LineGroup::Member.where(line_id: global_scope.lines.select(:id).distinct).select(:group_id).distinct
      )
    end

    collection :companies do
      current_collection.where(
        id: global_scope.lines.where.not(company_id: nil).select(:company_id).distinct
      ).or(
        current_collection.where(
          id: global_scope.lines.where.not(secondary_company_ids: nil).select('unnest(secondary_company_ids)').distinct
        )
      ).distinct
    end

    collection :fare_products do
      current_collection.where(company: global_scope.companies).or(current_collection.where(company: nil))
    end

    collection :networks do
      current_collection.where(id: global_scope.lines.where.not(network_id: nil).select(:network_id).distinct)
    end

    collection :contracts do
      current_collection.with_lines(global_scope.lines)
    end

    collection :line_notices do
      current_collection.with_lines(global_scope.lines)
    end
  end
end
