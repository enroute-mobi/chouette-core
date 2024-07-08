# frozen_string_literal: true

class UpdateEmptyStringsOfAuthenticationsSamlAuthnContextsToNull < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      execute(%(UPDATE "authentications" SET saml_authn_context = NULL WHERE saml_authn_context = ''))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
