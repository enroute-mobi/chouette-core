# frozen_string_literal: true

module Query
  class StopArea < Base
    # Select in the current scope Stop Areas which are the ancestors
    # of the given Stop Areas .. and the given Stop Areas themselves
    #
    # For example, into an Export:
    #
    #    Query::StopArea.new(stop_area_referential.stop_areas).self_and_ancestors(export_scope.stop_areas)
    #
    # TODO Could use a nice RecurviseQuery common object
    def self_and_ancestors(relation) # rubocop:disable Metrics/MethodLength
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
    def ancestors(relation) # rubocop:disable Metrics/MethodLength
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
    def self_referents_and_ancestors(relation) # rubocop:disable Metrics/MethodLength
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

    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        objectid = scope.arel_table[:objectid]
        registration_number = scope.arel_table[:registration_number]
        scope.where(name.matches("%#{value}%")).or(scope.where(objectid.matches("%#{value}%"))).or(scope.where(registration_number.matches("%#{value}%")))
      end
    end

    def area_type(value)
      where(value, :in, :area_type)
    end

    def zip_code(value)
      where(value, :matches, :zip_code)
    end

    def city_name(value)
      where(value, :matches, :city_name)
    end

    def stop_area_provider_id(value)
      where(value, :eq, :stop_area_provider_id)
    end

    def is_referent(value)
      change_scope(if: value.present?) do |scope|
        scope.where(is_referent: value)
      end
    end

    def statuses(statuses)
      change_scope(if: statuses.present?) do |scope|
        query = []
        query << 'deleted_at IS NOT NULL' if statuses.include?('deactivated')
        query << '(confirmed_at IS NULL AND deleted_at IS NULL)' if statuses.include?('in_creation')
        query << '(confirmed_at IS NOT NULL AND deleted_at IS NULL)' if statuses.include?('confirmed')

        scope.where(query.join(' OR '))
      end
    end

    def parent_id(value)
      where(value, :eq, :parent_id)
    end

    # TODO: Could use a nice RecurviseQuery common object
    delegate :table_name, to: Chouette::StopArea
    private :table_name

    # private
  end
end
