class CompaniesController < BreadcrumbController
  include ApplicationHelper
  before_action :check_policy, :only => [:edit, :update, :destroy]
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
      }
      build_breadcrumb :index
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
    @q = line_referential.companies.search(params[:q])
    @companies ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
  end


  def resource_url(company = nil)
    line_referential_company_path(line_referential, company || resource)
  end

  def collection_url
    line_referential_companies_path(line_referential)
  end

  alias_method :line_referential, :parent

  def check_policy
    authorize resource
  end

  def company_params
    params.require(:company).permit( :objectid, :object_version, :creation_time, :creator_id, :name, :short_name, :organizational_unit, :operating_department_name, :code, :phone, :fax, :email, :registration_number, :url, :time_zone )
  end

end
