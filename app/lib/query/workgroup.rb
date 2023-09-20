# frozen_string_literal: true

module Query
  class Workgroup < Base
    def name(value)
      where(value, :matches, :name)
    end

    def owner(value)
      change_scope(if: value.present?) do |scope|
        scope.where(owner: value)
      end
    end
  end
end
