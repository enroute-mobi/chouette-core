class ReferentialLinesController < ChouetteController
  include ReferentialSupport
  include PolicyChecker

  defaults :resource_class => Chouette::Line, :collection_name => 'lines', :instance_name => 'line'
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :kml, :only => :show
  respond_to :js, :only => :index

  belongs_to :referential

  def show
    @q = resource.routes.ransack(params[:q])
    @routes = @q.result

    case sort_route_column
    when "stop_points", "journey_patterns"
      left_join = %Q{LEFT JOIN "#{sort_route_column}" ON "#{sort_route_column}"."route_id" = "routes"."id"}

      @routes = @routes.joins(left_join).group(:id).order(Arel.sql("count(#{sort_route_column}.route_id) #{sort_route_direction}"))
    else
      @routes = @routes.order(Arel.sql("lower(#{sort_route_column}) #{sort_route_direction}"))
    end

    @routes = @routes.paginate(page: params[:page], per_page: 10)

    @routes = RouteDecorator.decorate(
      @routes,
      context: {
        referential: referential,
        line: @line
      }
    )

    show! do
      @line = ReferentialLineDecorator.decorate(
        @line,
        context: {
          referential: referential,
          current_organisation: current_organisation
        }
      )
    end
  end

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion)
  def destroy_resource(object)
    object.delete
  end

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

  protected

  def build_resource
    super.tap do |resource|
      resource.line_referential = referential.line_referential
    end
  end

  def filtered_lines_maps
    filtered_lines.collect do |line|
      { :id => line.id, :name => (line.published_name ? line.published_name : line.name) }
    end
  end

  def filtered_lines
    referential.lines.by_text(params[:q])
  end

  def collection
    %w(network_id company_id group_of_lines_id comment_id transport_mode).each do |filter|
      if params[:q] && params[:q]["#{filter}_eq"] == '-1'
        params[:q]["#{filter}_eq"] = ''
        params[:q]["#{filter}_blank"] = '1'
      end
    end

    @q = referential.lines.ransack(params[:q])

    if sort_column && sort_direction
      @lines ||= @q.result(:distinct => true).order(sort_column + ' ' + sort_direction)
    else
      @lines ||= @q.result(:distinct => true).order(:number)
    end
    @lines = @lines.paginate(page: params[:page], per_page: 10).includes([:network, :company])
  end

  private

  def sort_column
    referential.lines.column_names.include?(params[:sort]) ? params[:sort] : 'number'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def sort_route_column
    (@line.routes.column_names + %w{stop_points journey_patterns}).include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_route_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def line_params
    params.require(:line).permit(
      :transport_mode,
      :transport_submode,
      :network_id,
      :company_id,
      :objectid,
      :object_version,
      :name, :number,
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
      :stable_id
      )
  end

end
