# frozen_string_literal: true

class CreateAuthentications < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      create_table :authentications do |t|
        t.references :organisation, null: false, index: false, foreign_key: true
        t.string :name, null: false
        t.string :type, null: false, index: true
        t.string :subtype
        t.timestamps null: false

        t.string :saml_idp_entity_id, index: true
        t.string :saml_idp_sso_service_url
        t.string :saml_idp_slo_service_url
        t.text :saml_idp_cert
        t.string :saml_idp_cert_fingerprint
        t.string :saml_idp_cert_fingerprint_algorithm
        t.string :saml_authn_context
        t.string :saml_email_attribute

        t.index %i[organisation_id name], unique: true
      end
    end
  end
end
