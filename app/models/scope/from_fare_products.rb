# frozen_string_literal: true

module Scope
  class FromFareProducts < Base
    collection :fare_validities do
      # TODO: we should filter Validities according zones & exported stop areas
      current_collection.by_products(global_scope.fare_products)
    end
  end
end
