# frozen_string_literal: true

class LinesController < Chouette::LineReferentialController
  include ApplicationHelper
  include TransportModeFilter

  defaults :resource_class => Chouette::Line

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show autocomplete]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html, :xml, :json
  respond_to :js, :only => :index

  helper_method :candidate_line_providers

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
            workbench: workbench,
            line_referential: line_referential,
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
      @line = @line.decorate(
        context: {
          workbench: workbench,
          line_referential: line_referential,
          current_organisation: current_organisation
        }
      )
    end
  end

  def new
    build_resource
    @line.transport_mode, @line.transport_submode = workgroup.default_transport_mode
    super
  end

  def update
    update! do
      if line_params[:line_notice_ids]
        workbench_line_referential_line_line_notices_path workbench, @line
      else
        workbench_line_referential_line_path workbench, @line
      end
    end
  end

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion)
  def destroy_resource(object)
    object.delete
  end

  def name_filter
    respond_to do |format|
      format.json { render :json => filtered_lines_maps}
    end
  end

  protected

  def build_resource
    get_resource_ivar || super.tap do |line|
      line.line_provider ||= workbench.default_line_provider
    end
  end

  def scope
    parent.lines
  end

  def search
    @search ||= Search::Line.from_params(params, line_referential: line_referential)
  end

  def collection
    @collection ||= search.search scope
  end

  def candidate_line_providers
    @candidate_line_providers ||= workbench.line_providers.order(:name)
  end

  delegate :workgroup, to: :workbench, allow_nil: true

  private

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
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :accessibility_limitation_description,
      :flexible_service,
      :group_of_lines,
      :group_of_line_ids,
      :group_of_line_tokens,
      :url,
      :color,
      :text_color,
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

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
