module Query
  class Line < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        objectid = scope.arel_table[:objectid]
        registration_number = scope.arel_table[:registration_number]
        scope.where(name.matches("%#{value}%")).or( scope.where(objectid.matches("%#{value}%"))).or( scope.where(registration_number.matches("%#{value}%")))
      end
    end

    def network_id(value)
      where(value, :eq, :network_id)
    end

    def company_id(value)
      where(value, :eq, :company_id)
    end

    def line_provider_id(value)
      where(value, :eq, :line_provider_id)
    end

    def transport_mode(value)
      where(value, :in, :transport_mode)
    end

    def line_status(status)
      change_scope(if: status.present?) do |scope|
        if status == "deactivated"
          scope.where(deactivated: true)
        else
          scope.where(deactivated: false)
        end
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where('daterange(active_from, active_until) && ? OR (active_from IS NULL AND active_until IS NULL)', period.to_postgresql_daterange)
      end
    end

    # TODO Could use a nice RecurviseQuery common object
    delegate :table_name, to: Chouette::Line
    private :table_name

    # private

  end
end
