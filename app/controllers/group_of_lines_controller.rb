class GroupOfLinesController < BreadcrumbController
  include ApplicationHelper
  before_action :check_policy, :only => [:edit, :update, :destroy]
  defaults :resource_class => Chouette::GroupOfLine
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :kml, :only => :show
  respond_to :js, :only => :index

  belongs_to :line_referential

  def show
    @map = GroupOfLineMap.new(resource).with_helpers(self)
    @lines = resource.lines.order(:name)
    show! do
      build_breadcrumb :show
    end
  end

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
        build_breadcrumb :index
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

  def name_filter
    respond_to do |format|
      format.json { render :json => filtered_group_of_lines_maps}
    end
  end


  protected

  def filtered_group_of_lines_maps
    filtered_group_of_lines.collect do |group_of_line|
      { :id => group_of_line.id, :name => group_of_line.name }
    end
  end

  def filtered_group_of_lines
    line_referential.group_of_lines.select{ |t| t.name =~ /#{params[:q]}/i  }
  end

  def collection
    @q = line_referential.group_of_lines.search(params[:q])
    @group_of_lines ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
  end

  def resource_url(group_of_line = nil)
    line_referential_group_of_line_path(line_referential, group_of_line || resource)
  end

  def collection_url
    line_referential_group_of_lines_path(line_referential)
  end

  alias_method :line_referential, :parent

  private

  def check_policy
    authorize resource
  end

  def group_of_line_params
    params.require(:group_of_line).permit( :objectid, :object_version, :creation_time, :creator_id, :name, :comment, :lines, :registration_number, :line_tokens)
  end

end
