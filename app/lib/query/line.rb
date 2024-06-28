module Query
  class Line < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")
        registration_number = table[:registration_number].matches("%#{value}%")
        number = table[:number].matches("%#{value}%")

        scope.where(name.or(objectid).or(registration_number).or(number))
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

    def statuses(status)
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

    def is_referent(value)
      change_scope(if: !value.nil?) do |scope|
        scope.where(is_referent: value)
      end
    end

    # Select in the current scope Lines which are the referents of the given Lines .. and the given Lines themselves
    #
    # For example, into an Export:
    #
    #    Query::Line.new(line_referential.lines).self_and_referents(export_scope.lines)
    #
    # TODO Could use a nice RecurviseQuery common object
    def self_and_referents(relation) # rubocop:disable Metrics/MethodLength
      tree_sql = <<-SQL
        WITH RECURSIVE referent_tree(id) AS (
           #{relation.select(:id).to_sql}
          UNION
            SELECT #{table_name}.referent_id
            FROM referent_tree
            JOIN #{table_name} ON #{table_name}.id = referent_tree.id
            WHERE #{table_name}.referent_id is not null
        )
        SELECT id FROM referent_tree
      SQL
      scope.where("#{table_name}.id IN (#{tree_sql})")
    end

    # TODO Could use a nice RecurviseQuery common object
    delegate :table_name, to: Chouette::Line
    private :table_name

    # private

  end
end
