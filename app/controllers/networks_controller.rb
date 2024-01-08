class NetworksController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Chouette::Network

  belongs_to :workbench
  belongs_to :line_referential, singleton: true

  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  def show
    show! do
      @network = @network.decorate(context: {
        workbench: @workbench,
        line_referential: line_referential
      })
    end
  end

  def new
    authorize resource_class
    new!
  end

  def create
    authorize resource_class
    build_resource
    super
  end

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @networks = decorate_networks(@networks)
      }

      format.js {
        @networks = decorate_networks(@networks)
      }
    end
  end

  protected

  def collection
    @q = line_referential.networks.ransack(params[:q])

    if sort_column && sort_direction
      @networks ||= @q.result(:distinct => true).order(sort_column + ' ' + sort_direction).paginate(:page => params[:page])
    else
      @networks ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
    end
  end

  alias_method :line_referential, :parent

  alias_method :current_referential, :line_referential
  helper_method :current_referential

  def network_params
    params.require(:network).permit(:objectid, :object_version, :version_date, :description, :name, :registration_number, :source_name, :source_type_name, :source_identifier, :comment )
  end

  private

  def build_resource
    get_resource_ivar || super.tap do |network|
      network.line_provider ||= @workbench.default_line_provider
    end
  end

  def sort_column
    line_referential.networks.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def decorate_networks(networks)
    NetworkDecorator.decorate(
      networks,
      context: {
        workbench: @workbench,
        line_referential: line_referential
      }
    )
  end

end
