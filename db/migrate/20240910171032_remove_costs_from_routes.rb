# frozen_string_literal: true

class RemoveCostsFromRoutes < ActiveRecord::Migration[5.2]
  def change
    remove_column :routes, :costs
  end
end
