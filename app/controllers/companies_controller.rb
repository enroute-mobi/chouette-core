# frozen_string_literal: true

class CompaniesController < Chouette::LineReferentialController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Chouette::Company

  respond_to :html
  respond_to :json

  around_action :set_current_workgroup

  def autocomplete
    scope = line_referential.companies
    scope = scope.referent_only if params[:referent_only]
    args  = [].tap{|arg| 4.times{arg << "%#{params[:q]}%"}}
    @companies = scope.where("unaccent(name) ILIKE unaccent(?) OR unaccent(short_name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?", *args).limit(50)
    @companies
  end

  def index
    index! do |format|
      format.html {
        @companies = CompanyDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
          }
        )
      }

      format.json {
        render json: @companies.to_json
      }
    end
  end

  def show
    show! do
      @company = resource.decorate(
        context: {
          workbench: workbench,
        }
      )
    end
  end

  protected

  def build_resource
    get_resource_ivar || super.tap do |company|
      company.line_provider ||= workbench.default_line_provider
    end
  end

  def scope
    parent.companies
  end

  def search
    @search ||= Search::Company.from_params(params, line_referential: line_referential)
  end

  def collection
    @collection ||= search.search scope
  end

  def set_current_workgroup(&block)
    # Ensure that InheritedResources has defined parents (workbench, etc)
    association_chain

    CustomFieldsSupport.within_workgroup current_workgroup, &block
  end

  def company_params
    fields = [
      :objectid,
      :object_version,
      :name,
      :short_name,
      :default_language,
      :default_contact_organizational_unit,
      :default_contact_operating_department_name,
      :code,
      :default_contact_phone,
      :default_contact_fax,
      :default_contact_email,
      :registration_number,
      :default_contact_url,
      :time_zone,
      :is_referent,
      :referent_id,
      :house_number,
      :address_line_1,
      :address_line_2,
      :street,
      :town,
      :postcode,
      :postcode_extension,
      :country_code,
      :fare_url,
      codes_attributes: [:id, :code_space_id, :value, :_destroy]
    ]
    fields += %w(default_contact private_contact customer_service_contact).product(%w(name email phone url more)).map{ |k| k.join('_')}
    fields += permitted_custom_fields_params(Chouette::Company.custom_fields(line_referential.workgroup))
    params.require(:company).permit(fields)
  end

end
