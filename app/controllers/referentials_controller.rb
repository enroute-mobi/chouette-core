class ReferentialsController < ChouetteController
  defaults :resource_class => Referential
  before_action :load_workbench
  include PolicyChecker

  respond_to :html
  respond_to :json, :only => :show
  respond_to :js, :only => :show

  before_action :check_cloning_source_is_accessible, only: %i(new create)

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

  def select_compliance_control_set
    @compliance_control_sets = ComplianceControlSet.where(organisation: current_organisation)
  end

  def validate
    ComplianceControlSetCopyWorker.perform_async(params[:compliance_control_set], params[:id])
    flash[:notice] = t('notice.referentials.validate')
    redirect_to workbench_compliance_check_sets_path(referential.workbench_id)
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

    redirect_to workbench_path(referential.workbench_id)
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
    @q = resource.lines.includes(:company, :network).search(params[:q])

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
    referential.ready = true
    super
  end

  def build_referential
    if params[:from]
      source_referential = Referential.find(params[:from])
      @referential = Referential.new_from(source_referential, current_organisation)
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
    params.require(:referential).permit(
      :id,
      :name,
      :organisation_id,
      :data_format,
      :archived_at,
      :created_from_id,
      :workbench_id,
      metadatas_attributes: [:id, :first_period_begin, :first_period_end, periods_attributes: [:begin, :end, :id, :_destroy], :lines => []]
    )
  end

  def check_cloning_source_is_accessible
    return unless params[:from]
    source = Referential.find params[:from]
    return user_not_authorized unless current_user.organisation.workgroups.include?(source.workbench.workgroup)
  end

  def load_workbench
    @workbench ||= Workbench.find(params[:workbench_id]) if params[:workbench_id]
    @workbench ||= resource&.workbench if params[:id]
    @workbench
  end

  alias_method :current_workbench, :load_workbench
  helper_method :current_workbench
end
