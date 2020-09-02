ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "bigserial primary key"

class ActiveRecord::Migration
  def on_public_schema_only
    yield if Apartment::Tenant.current == "public"
  end

  def not_in_public_schema
    yield if Apartment::Tenant.current != "public"
  end
end
