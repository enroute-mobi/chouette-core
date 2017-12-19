class LinesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker
  include LineReferentialInOrganisationChecker

  defaults :resource_class => Chouette::Line
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :kml, :only => :show
  respond_to :js, :only => :index

  belongs_to :line_referential


  def index
    @hide_group_of_line = line_referential.group_of_lines.empty?
    index! do |format|
      @lines = ModelDecorator.decorate(
        @lines,
        with: LineDecorator,
        context: {
          line_referential: @line_referential,
          current_organisation: current_organisation
        }
      )

      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
      }
    end
  end

  def show
    @group_of_lines = resource.group_of_lines
    show! do
      @line = @line.decorate(context: {
        line_referential: @line_referential,
        current_organisation: current_organisation
      })
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

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion
  def destroy_resource(object)
    object.delete
  end


  protected

  def filtered_lines_maps
    filtered_lines.collect do |line|
      { :id => line.id, :name => (line.published_name ? line.published_name : line.name) }
    end
  end

  def filtered_lines
    line_referential.lines.by_text(params[:q])
  end

  def collection
    %w(network_id company_id group_of_lines_id comment_id transport_mode).each do |filter|
      if params[:q] && params[:q]["#{filter}_eq"] == '-1'
        params[:q]["#{filter}_eq"] = ''
        params[:q]["#{filter}_blank"] = '1'
      end
    end
    @q = line_referential.lines.search(params[:q])

    if sort_column && sort_direction
      @lines ||= @q.result(:distinct => true).order(sort_column + ' ' + sort_direction).paginate(:page => params[:page]).includes([:network, :company])
    else
      @lines ||= @q.result(:distinct => true).order(:number).paginate(:page => params[:page]).includes([:network, :company])
    end
  end

  alias_method :line_referential, :parent


  private

  def delete_all
    objects =
      get_collection_ivar || set_collection_ivar(end_of_association_chain.where(:id => params[:ids]))
    objects.each { |object| object.delete }
    respond_with(objects, :location => smart_collection_url)
  end

  def name_filter
    respond_to do |format|
      format.json { render :json => filtered_lines_maps}
    end
  end

  def sort_column
    (Chouette::Line.column_names + ['companies.name', 'networks.name']).include?(params[:sort]) ? params[:sort] : 'number'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  alias_method :current_referential, :line_referential
  helper_method :current_referential

  def line_params
    params.require(:line).permit(
      :transport_mode,
      :network_id,
      :company_id,
      :objectid,
      :object_version,
      :name,
      :number,
      :published_name,
      :transport_mode,
      :registration_number,
      :comment,
      :mobility_restricted_suitability,
      :int_user_needs,
      :flexible_service,
      :group_of_lines,
      :group_of_line_ids,
      :group_of_line_tokens,
      :url,
      :color,
      :text_color,
      :stable_id,
      :transport_submode,
      :secondary_company_ids => [],
      footnotes_attributes: [:code, :label, :_destroy, :id]
    )
  end

end
