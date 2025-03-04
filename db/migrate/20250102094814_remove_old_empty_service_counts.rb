# frozen_string_literal: true

class RemoveOldEmptyServiceCounts < ActiveRecord::Migration[5.2]
  def change
    ServiceCount.where(line_id: nil) \
                .or(ServiceCount.where(route_id: nil)) \
                .or(ServiceCount.where(journey_pattern_id: nil)) \
                .delete_all
  end
end
