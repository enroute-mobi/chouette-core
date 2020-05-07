class CompaniesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker
  defaults :resource_class => Chouette::Company
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  belongs_to :line_referential

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @companies = decorate_companies(@companies)
      }

      format.json {
        render json: @companies.to_json
      }
    end
  end

  def new
    authorize resource_class
    super
  end

  def create
    authorize resource_class
    super
  end


  protected

  def collection
    scope = line_referential.companies
    @q = scope.ransack(params[:q])
    ids = @q.result(:distinct => true).pluck(:id)
    scope = scope.where(id: ids)
    if sort_column && sort_direction
      @companies ||= scope.order(Arel.sql("lower(#{sort_column})" + ' ' + sort_direction)).paginate(:page => params[:page])
    else
      @companies ||= scope.order('lower(name)').paginate(:page => params[:page])
    end
  end

  def resource
    super.decorate(context: { referential: line_referential })
  end

  def resource_url(company = nil)
    line_referential_company_path(line_referential, company || resource)
  end

  def collection_url
    line_referential_companies_path(line_referential)
  end

  alias_method :line_referential, :parent

  alias_method :current_referential, :line_referential
  helper_method :current_referential

  def company_params
    fields = [:objectid, :object_version, :name, :short_name, :default_language, :default_contact_organizational_unit, :default_contact_operating_department_name, :code, :default_contact_phone, :default_contact_fax, :default_contact_email, :registration_number, :default_contact_url, :time_zone]
    fields += [:house_number, :address_line_1, :address_line_2, :street, :town, :postcode, :postcode_extension ,:country_code]
    fields += permitted_custom_fields_params(Chouette::Company.custom_fields(line_referential.workgroup))
    fields += %w(default_contact private_contact customer_service_contact).product(%w(name email phone url more)).map{ |k| k.join('_')}
    params.require(:company).permit( fields )
  end

  private

  def sort_column
    line_referential.companies.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def decorate_companies(companies)
    CompanyDecorator.decorate(
      companies,
      context: {
        referential: line_referential
      }
    )
  end

end
