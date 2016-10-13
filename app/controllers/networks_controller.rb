class NetworksController < BreadcrumbController
  include ApplicationHelper
  before_action :check_policy, :only => [:edit, :update, :destroy]
  defaults :resource_class => Chouette::Network
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :kml, :only => :show
  respond_to :js, :only => :index

  belongs_to :line_referential

  def show
    @map = NetworkMap.new(resource).with_helpers(self)
    show! do
      build_breadcrumb :show
    end
  end

  def new
    authorize resource_class
  end

  def create
    authorize resource_class
  end

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

  protected

  def collection
    @q = line_referential.networks.search(params[:q])
    @networks ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
  end

  def resource_url(network = nil)
    line_referential_network_path(line_referential, network || resource)
  end

  def collection_url
    line_referential_networks_path(line_referential)
  end

  alias_method :line_referential, :parent

  def check_policy
    authorize resource
  end

  def network_params
    params.require(:network).permit(:objectid, :object_version, :creation_time, :creator_id, :version_date, :description, :name, :registration_number, :source_name, :source_type_name, :source_identifier, :comment )
  end
end
