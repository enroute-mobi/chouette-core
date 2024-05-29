module Query
  class Company < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")

        scope.where(name.or(objectid))
      end
    end

    def without_country
      scope.where(country_code: nil)
    end

    def is_referent(value)
      where(value, :eq, :is_referent)
    end
  end
end
