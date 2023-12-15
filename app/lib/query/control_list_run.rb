module Query
  class ControlListRun < Query::Operation
    def name(value)
      where(value, :matches, :name)
    end

    def referential_name(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:referential).where('referentials.name LIKE ?', "%#{value}%")
      end
    end
  end
end
