# frozen_string_literal: true

module Delayed
  # Used to customize Delayed::Backend::ActiveRecord::Job
  #
  # Fixes PostgreSQL SQL to ensure reservation uniqueness
  # See https://github.com/collectiveidea/delayed_job_active_record/pull/169
  module UniqReservation
    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def reserve_with_scope_using_optimized_postgres(ready_scope, worker, now)
        # Custom SQL required for PostgreSQL because postgres does not support UPDATE...LIMIT
        # This locks the single record 'FOR UPDATE' in the subquery
        # http://www.postgresql.org/docs/9.0/static/sql-select.html#SQL-FOR-UPDATE-SHARE
        # Note: active_record would attempt to generate UPDATE...LIMIT like
        # SQL for Postgres if we use a .limit() filter, but it would not
        # use 'FOR UPDATE' and we would have many locking conflicts
        quoted_name = connection.quote_table_name(table_name)
        subquery    = ready_scope.limit(1).lock(true).select('id').to_sql
        sql         = "UPDATE #{quoted_name} SET locked_at = ?, locked_by = ? WHERE id = (#{subquery}) RETURNING *"
        reserved    = find_by_sql([sql, now, worker.name])
        reserved[0]
      end
    end
  end
end
