module Query
  class StopArea < Base
    # Select in the current scope Stop Areas which are the ancestors
    # of the given Stop Areas .. and the given Stop Areas themselves
    #
    # For example, into an Export:
    #
    #    Query::StopArea.new(stop_area_referential).self_and_ancestors(export_scope.stop_areas)
    #
    # TODO Could use a nice RecurviseQuery common object
    def self_and_ancestors(relation)
      tree_sql = <<-SQL
        WITH RECURSIVE parent_tree(id) AS (
           #{relation.select(:id).to_sql}
          UNION
            SELECT #{table_name}.parent_id
            FROM parent_tree
            JOIN #{table_name} ON #{table_name}.id = parent_tree.id
            WHERE #{table_name}.parent_id is not null
        )
        SELECT id FROM parent_tree
      SQL
      scope.where("#{table_name}.id IN (#{tree_sql})")
    end

    # Select in the current scope Stop Areas which are the ancestors of the given Stop Areas
    # TODO Could use a nice RecurviseQuery common object
    def ancestors(relation)
      tree_sql = <<-SQL
        WITH RECURSIVE parent_tree(id) AS (
           #{relation.where.not(parent_id: nil).select(:parent_id).distinct.to_sql}
          UNION
            SELECT #{table_name}.parent_id
            FROM parent_tree
            JOIN #{table_name} ON #{table_name}.id = parent_tree.id
            WHERE #{table_name}.parent_id is not null
        )
        SELECT id FROM parent_tree
      SQL
      scope.where("#{table_name}.id IN (#{tree_sql})")
    end

    # Select in the current scope Stop Areas which are the ancestors or referents
    # of the given Stop Areas .. and the given Stop Areas themselves
    # TODO Could use a nice RecurviseQuery common object
    def self_referents_and_ancestors(relation)
      tree_sql = <<-SQL
        WITH RECURSIVE tree(id) AS (
           #{relation.select(:id).to_sql}
          UNION
            (
              SELECT unnest(array[#{table_name}.parent_id, #{table_name}.referent_id])
              FROM tree
              JOIN #{table_name} ON #{table_name}.id = tree.id
              WHERE #{table_name}.parent_id is not null or #{table_name}.referent_id is not null
            )
        )
        SELECT id FROM tree
      SQL
      scope.where("#{table_name}.id IN (#{tree_sql})")
    end

    def without_referent
      scope.where(referent: nil)
    end

    def without_parent
      scope.where(parent: nil)
    end

    def without_coordinates
      scope.where(latitude: nil).or(scope.where(longitude: nil))
    end

    def without_country
      scope.where(country_code: nil)
    end

    # TODO Could use a nice RecurviseQuery common object
    delegate :table_name, to: Chouette::StopArea
    private :table_name
  end
end
