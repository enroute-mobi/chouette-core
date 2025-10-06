# frozen_string_literal: true

class ReferentialsController < Chouette::WorkbenchController
  defaults :resource_class => Referential

  respond_to :html
  respond_to :json, :only => :show
  respond_to :js, :only => :show

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show journey_patterns]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  before_action :authorize_clone_resource_on_new, only: :new
  before_action :authorize_clone_resource_on_create, only: :create
  before_action :resource, only: :show
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
      @referential = @referential.decorate(context: { workbench: @workbench })
      @reflines = ReferentialLineDecorator.decorate(
        collection,
        context: {
          referential: referential,
          workbench: @workbench,
          current_organisation: current_organisation
        }
      )
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
    redirect_to workbench_referential_line_route_journey_patterns_path(current_workbench, referential, jp.route.line, jp.route)
  end

  def policy_context_class
    if current_referential
      ::Policy::Context::Referential
    else
      ::Policy::Context::Workbench
    end
  end

  protected

  alias_method :referential, :resource

  def resource
    @referential ||= workbench.find_referential!(params[:id]).visited!.decorate
  end

  def scope
    @referential.lines
  end

  def search
    @search ||= Search::Line.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  def build_resource
    if @source_referential
      @referential = Referential.new_from(@source_referential, current_workbench)
    else
      super.tap do |referential|
        referential.user_id = current_user.id
        referential.user_name = current_user.name
      end
    end
  end

  def build_referential
    @referential.data_format = current_organisation.data_format
    @referential.workbench_id ||= params[:workbench_id]
    if @referential.in_workbench?
      @referential.init_metadatas default_date_range: Range.new(Date.today, Date.today.advance(months: 1))
    end
  end

  def create_resource(referential)
    referential.organisation = current_organisation
    referential.ready = true unless ( referential.created_from || referential.from_current_offer)
    super
  end

  def current_referential
    return nil unless params[:id]

    resource
  rescue ActiveRecord::RecordNotFound
    nil
  end
  helper_method :current_referential

  private

  def authorize_clone_resource_on_new
    return unless params[:from].present? # rubocop:disable Rails/Blank

    @source_referential = authorize_clone_resource(params[:from])
  end

  def authorize_clone_resource_on_create
    return unless params[:referential] && params[:referential][:created_from_id].present?

    source_referential = authorize_clone_resource(params[:referential][:created_from_id])

    referential_params[:created_from] = source_referential
  end

  def authorize_clone_resource(from_id)
    source_referential = workbench.all_referentials.find(from_id)
    authorize(source_referential, :clone?)
    source_referential
  end

  def referential_params
    return @referential_params if @referential_params

    referential_params = params.require(:referential).permit(
      :id,
      :name,
      :organisation_id,
      :data_format,
      :archived_at,
      :workbench_id,
      :from_current_offer,
      :urgent,
      metadatas_attributes: [:id, :first_period_begin, :first_period_end, periods_attributes: [:begin, :end, :id, :_destroy], :lines => []]
    )
    referential_params[:from_current_offer] = referential_params[:from_current_offer] == 'true'
    referential_params[:urgent] = referential_params[:urgent] == 'true' && \
                                  policy(
                                    current_workbench.referentials.build(
                                      organisation: current_organisation
                                    )
                                  ).flag_urgent?
    @referential_params = referential_params
  end

  def check_lines_outside_of_functional_scope
    if (lines = @referential.lines_outside_of_scope).exists?
      flash[:warning] = I18n.t("referentials.show.lines_outside_of_scope", count: lines.count, lines: lines.pluck(:name).to_sentence, organisation: @referential.organisation.name)
    end
  end
end
