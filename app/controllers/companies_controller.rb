# frozen_string_literal: true

class CompaniesController < Chouette::LineReferentialController
  include ApplicationHelper

  defaults resource_class: Chouette::Company

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show autocomplete]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html
  respond_to :json

  def autocomplete
    scope = line_referential.companies
    scope = scope.referent_only if params[:referent_only]
    args  = [].tap { |arg| 4.times { arg << "%#{params[:q]}%" } }
    @companies = scope.where(
      'unaccent(name) ILIKE unaccent(?) OR unaccent(short_name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?', *args
    ).limit(50)
    @companies
  end

  def index
    index! do |format|
      format.html do
        @companies = CompanyDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end

      format.json do
        render json: @companies.to_json
      end
    end
  end

  def show
    show! do
      @company = resource.decorate(
        context: {
          workbench: workbench
        }
      )
    end
  end

  protected

  def scope
    parent.companies
  end

  def search
    @search ||= Search::Company.from_params(params, line_referential: line_referential)
  end

  def collection
    @collection ||= search.search scope
  end

  def company_params
    return @company_params if @company_params

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
      :line_provider_id,
      { codes_attributes: %i[id code_space_id value _destroy] }
    ]
    fields += %w[default_contact private_contact
                 customer_service_contact].product(%w[name email phone url more]).map do |k|
      k.join('_')
    end
    fields += permitted_custom_fields_params(Chouette::Company.custom_fields(line_referential.workgroup))
    @company_params = params.require(:company).permit(fields)
  end
end
