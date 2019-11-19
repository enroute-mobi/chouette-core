# Empty

def on_public_schema_only
  yield if Apartment::Tenant.current == "public"
end

on_public_schema_only do
  "Update user permissions according profiles"
  Permission::Profile.update_users_permissions
end
