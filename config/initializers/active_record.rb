ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "bigserial primary key"

class ActiveRecord::Migration
  def on_public_schema_only
    yield if Apartment::Tenant.current == "public"
  end

  def on_referential_schemas_only
    yield if Apartment::Tenant.current != "public"
  end
end

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter

  # Create extension only when needed and into our shared_extensions schema
  def enable_extension(name)
    Extension.new(self, name).enable do
      reload_type_map
    end
  end

  class Extension

    attr_reader :name, :adapter
    def initialize(adapter, name)
      @adapter, @name = adapter, name
    end

    delegate :query_value, :exec_query, :quote, to: :adapter

    PLPGSQL = "plpgsql"

    SCHEMA_SHARED_EXTENSIONS = "shared_extensions"
    SCHEMA_PG_CATALOG = "pg_catalog"

    def plpgsql?
      name == PLPGSQL
    end

    def destination_schema
      plpgsql? ? SCHEMA_PG_CATALOG : SCHEMA_SHARED_EXTENSIONS
    end

    def enabled?
      query = <<~SQL
      SELECT true FROM pg_catalog.pg_extension e
      LEFT JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
      where e.extname = #{quote(name)} and n.nspname = #{quote(destination_schema)}
      SQL

      query_value query
    end

    def enable(&block)
      unless enabled?
        enable!
        block.call
      end
    end

    def enable!
      Rails.logger.info "Create extension #{name} in #{destination_schema}"

      query = "CREATE EXTENSION IF NOT EXISTS \"#{name}\" WITH SCHEMA #{destination_schema};"
      exec_query query
    end

  end


end

module ActiveRecord
  class SoleRecordExceeded < ActiveRecordError
    attr_reader :record

    def initialize(record = nil)
      @record = record
      super "Wanted only one #{record&.name || 'record'}"
    end
  end
end

module ActiveRecordSole
  extend ActiveSupport::Concern

  module ClassMethods
    def sole
      found, undesired = first(2)

      if found.nil?
        raise ActiveRecord::RecordNotFound
      elsif undesired.present?
        raise ActiveRecord::SoleRecordExceeded, self
      else
        found
      end
    end
  end
end

ActiveRecord::Base.include ActiveRecordSole
