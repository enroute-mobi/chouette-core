class LinesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker
  include TransportModeFilter

  defaults :resource_class => Chouette::Line

  belongs_to :workbench
  belongs_to :line_referential, singleton: true

  respond_to :html, :xml, :json
  respond_to :kml, :only => :show
  respond_to :js, :only => :index

  def autocomplete
    scope = line_referential.lines.referents

    query = 'unaccent(name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?'
    args = ["%#{params[:q]}%"] * 3

    @lines = scope.where(query, *args).limit(50)
  end

  def index
    index! do |format|
      format.html {
        @lines = LineDecorator.decorate(
          collection,
          context: {
            workbench: @workbench,
            line_referential: @line_referential,
            # TODO Remove me ?
            current_organisation: current_organisation
          }
        )
      }
    end
  end

  def show
    @group_of_lines = resource.group_of_lines
    show! do
      @line = @line.decorate(context: {
        workbench: @workbench,
        line_referential: @line_referential,
        current_organisation: current_organisation
      })
    end
  end

  def new
    authorize resource_class
    build_resource
    @line.transport_mode, @line.transport_submode = workgroup.default_transport_mode
    candidate_line_providers
    super
  end

  def edit
    candidate_line_providers
    edit!
  end

  def create
    authorize resource_class
    build_resource
    candidate_line_providers
    super
  end

  def update
    candidate_line_providers
    update! do
      if line_params[:line_notice_ids]
        workbench_line_referential_line_line_notices_path @workbench, @line
      else
        workbench_line_referential_line_path @workbench, @line
      end
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
    get_resource_ivar || super.tap do |line|
      line.line_provider ||= @workbench.default_line_provider
    end
  end

  def scope
    parent.lines
  end

  def search
    @search ||= Search::Line.new(scope, params, line_referential: line_referential)
  end

  delegate :collection, to: :search

  def workbench
    @workbench
  end

  def candidate_line_providers
    @candidate_line_providers ||= @workbench.line_providers.order(:name)
  end

  alias_method :line_referential, :parent
  delegate :workgroup, to: :workbench, allow_nil: true

  private

  alias_method :current_referential, :line_referential
  helper_method :current_referential

  def line_params
    out = params.require(:line)
    out = out.permit(
      :activated,
      :active_from,
      :active_until,
      :transport_mode,
      :network_id,
      :company_id,
      :objectid,
      :object_version,
      :name,
      :number,
      :published_name,
      :registration_number,
      :comment,
      :line_provider_id,
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
      :seasonal,
      :line_notice_ids,
      :is_referent,
      :referent_id,
      :secondary_company_ids => [],
      footnotes_attributes: [:code, :label, :_destroy, :id],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
    out[:line_notice_ids] = out[:line_notice_ids].split(',') if out[:line_notice_ids]
    out[:secondary_company_ids] = (out[:secondary_company_ids] || []).select(&:present?)
    out
  end

end
