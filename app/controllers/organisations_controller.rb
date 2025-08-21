# frozen_string_literal: true

class OrganisationsController < Chouette::ResourceController
  defaults resource_class: Organisation

  respond_to :html, only: %i[show edit update]

  def show
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    show! do
      @users = UserDecorator.decorate(users)
    end
  end

  def update
    update! do
      organisation_path
    end
  end

  def saved_searches
    @saved_searches ||= current_organisation.saved_searches.for(::Search::User)
  end

  protected

  def user_scope
    current_organisation.users
  end

  def user_search
    @search ||= ::Search::User.from_params(params, organisation: current_organisation) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def users
    @users ||= user_search.search(user_scope)
  end

  def resource
    @organisation = current_organisation.decorate
  end

  private

  def organisation_params
    result = params.require(:organisation).permit(
      :name,
      authentication_attributes: %i[
        id
        type
        name
        subtype
        saml_idp_entity_id
        saml_idp_entity_id
        saml_idp_sso_service_url
        saml_idp_slo_service_url
        saml_idp_cert
        saml_idp_cert_fingerprint
        saml_idp_cert_fingerprint_algorithm
        saml_authn_context
        saml_email_attribute
      ]
    )
    result[:authentication_attributes][:_destroy] = '1' if result[:authentication_attributes][:type].blank?
    result
  end
end
