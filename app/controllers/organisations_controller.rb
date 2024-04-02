# frozen_string_literal: true

class OrganisationsController < Chouette::ResourceController
  defaults resource_class: Organisation

  respond_to :html, only: %i[show edit update]

  def show
    show! do
      @q = @organisation.users.ransack(params[:q])
      @users = UserDecorator.decorate(
        @q.result.paginate(page: params[:page]).order(sort_params)
      )
    end
  end

  def update
    update! do
      organisation_path
    end
  end

  protected

  def update_resource(object, attributes)
    organisation_attributes = attributes[0].except(:authentication)
    object.attributes = organisation_attributes
    authentication_attributes = attributes[0][:authentication]
    # TODO destruction if all attributes are blank
    if object.authentication
      object.authentication.attributes = authentication_attributes
    else
      object.build_authentication(authentication_attributes)
    end
    object.transaction { object.authentication.save && object.save }
  end

  private

  def sort_column
    %w[name email].include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def sort_params
    "#{sort_column} #{sort_direction}"
  end

  def resource
    @organisation = current_organisation.decorate
  end

  def organisation_params
    params.require(:organisation).permit(
      :name,
      authentication: %i[
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
  end
end
