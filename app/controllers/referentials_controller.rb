class ReferentialsController < ChouetteController
  defaults :resource_class => Referential
  before_action :load_workbench
  include PolicyChecker

  respond_to :html
  respond_to :json, :only => :show
  respond_to :js, :only => :show

  before_action :check_cloning_source_is_accessible, only: %i(new create)
  before_action :check_lines_outside_of_functional_scope, only: :show

  def index
    redirect_to @workbench
  end

  def new
    new! do
      build_referential
    end
  end

  def create
    create! do |success, failure|
      success.html do
        if @referential.created_from_id.present?
          flash[:notice] = t('notice.referentials.duplicate')
        else
          flash[:notice] = t('notice.referentials.create')
        end
        redirect_to workbench_path(@referential.workbench)
      end
      failure.html do
        Rails.logger.info "Can't create Referential : #{@referential.errors.inspect}"
        render :new
      end
    end
  end

  def show
    resource.switch if resource.ready?
    show! do |format|
      @referential = @referential.decorate()
      @reflines = lines_collection.paginate(page: params[:page], per_page: 10)
      @reflines = ReferentialLineDecorator.decorate(
        @reflines,
        context: {
          referential: referential,
          current_organisation: current_organisation
        }
      )

      format.json {
        render :json => { :lines_count => resource.lines.count,
               :networks_count => resource.networks.count,
               :vehicle_journeys_count => resource.vehicle_journeys.count + resource.vehicle_journey_frequencies.count,
               :time_tables_count => resource.time_tables.count,
               :referential_id => resource.id}
      }
    end
  end

  def edit
    edit! do
      if @referential.in_workbench?
        @referential.init_metadatas default_date_range: Range.new(Date.today, Date.today.advance(months: 1))
      end
    end
  end

  def update
    update!
    @referential.clean_routes_if_needed
  end

  def destroy
    workbench = referential.workbench_id

    referential.destroy!
    redirect_to workbench_path(workbench), notice: t('notice.referential.deleted')
  end

  def archive
    referential.archive!
    redirect_to workbench_path(referential.workbench_id), notice: t('notice.referential.archived')
  end

  def unarchive
    if referential.unarchive!
      flash[:notice] = t('notice.referential.unarchived')
    else
      flash[:alert] = t('notice.referential.unarchived_failed')
    end

    redirect_back fallback_location: root_path
  end

  def journey_patterns
    referential.switch
    jp = Chouette::JourneyPattern.find(params[:journey_pattern_id])
    redirect_to referential_line_route_journey_patterns_collection_path(referential, jp.route.line, jp.route)
  end

  protected

  alias_method :referential, :resource
  alias_method :current_referential, :referential
  helper_method :current_referential

  def resource
    @referential ||= current_organisation.find_referential(params[:id]).decorate
  end

  def collection
    @referentials ||= current_organisation.referentials.order(:name)
  end

  def lines_collection
    @q = resource.lines.includes(:company, :network).ransack(params[:q])

    if sort_column && sort_direction
      @reflines ||=
        begin
          reflines = @q.result(distinct: true).order(sort_column + ' ' + sort_direction)
          reflines = reflines.paginate(page: params[:page], per_page: 10)
          reflines
        end
    else
      @reflines ||=
        begin
          reflines = @q.result(distinct: true).order(:name)
          reflines = reflines.paginate(page: params[:page], per_page: 10)
          reflines
        end
    end
  end

  def build_resource
    super.tap do |referential|
      referential.user_id = current_user.id
      referential.user_name = current_user.name
    end
  end

  def create_resource(referential)
    referential.organisation = current_organisation
    referential.ready = true unless ( referential.created_from || referential.from_current_offer)
    super
  end

  def build_referential
    if params[:from]
      source_referential = Referential.find(params[:from])
      @referential = Referential.new_from(source_referential, current_workbench)
    end

    @referential.data_format = current_organisation.data_format
    @referential.workbench_id ||= params[:workbench_id]
    if @referential.in_workbench?
      @referential.init_metadatas default_date_range: Range.new(Date.today, Date.today.advance(months: 1))
    end
  end

  private
  def sort_column
    sortable_columns = Chouette::Line.column_names + ['networks.name', 'companies.name']
    params[:sort] if sortable_columns.include?(params[:sort])
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def referential_params
    referential_params = params.require(:referential).permit(
      :id,
      :name,
      :organisation_id,
      :data_format,
      :archived_at,
      :created_from_id,
      :workbench_id,
      :from_current_offer,
      :urgent,
      metadatas_attributes: [:id, :first_period_begin, :first_period_end, periods_attributes: [:begin, :end, :id, :_destroy], :lines => []]
    )
    referential_params[:from_current_offer] = referential_params[:from_current_offer] == 'true'
    referential_params[:urgent] = policy(Referential.new(organisation: current_organisation)).flag_urgent? && referential_params[:urgent] == 'true'
    referential_params
  end

  def check_cloning_source_is_accessible
    return unless params[:from]
    source = Referential.find params[:from]
    return user_not_authorized unless current_user.organisation.workgroups.include?(source.workbench.workgroup)
  end

  def check_lines_outside_of_functional_scope
    if (lines = @referential.lines_outside_of_scope).exists?
      flash[:warning] = I18n.t("referentials.show.lines_outside_of_scope", count: lines.count, lines: lines.pluck(:name).to_sentence, organisation: @referential.organisation.name)
    end
  end

  def load_workbench
    @workbench ||= current_organisation.workbenches.find(params[:workbench_id]) if params[:workbench_id]
    @workbench ||= resource&.workbench if params[:id]
    @workbench
  end

  alias_method :current_workbench, :load_workbench
  helper_method :current_workbench
end
