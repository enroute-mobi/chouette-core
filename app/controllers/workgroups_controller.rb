class WorkgroupsController < ChouetteController
  defaults resource_class: Workgroup

  include PolicyChecker
  before_action :authorize_resource, only: %i[edit_controls update_controls]

  def edit_controls
    edit!
  end

  def update_controls
    update!
  end

  def create
    @workgroup = Workgroup.create_with_organisation current_organisation, workgroup_params
    redirect_to(@workgroup)
  rescue ActiveRecord::RecordInvalid => e
    @workgroup = Workgroup.new workgroup_params
    render :new
  end

  def index
    index! do |format|
      @workgroups = WorkgroupDecorator.decorate(@workgroups)

      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
      end
    end
  end

  def update
    unless resource.update workgroup_params
      if workgroup_params.has_key? :sentinel_min_hole_size
        render :edit_hole_sentinel
      else
        render :edit
      end
      return
    end

    redirect_to resource
  end

  def workgroup_params
    params.require(:workgroup).permit(
      :name,
      :sentinel_min_hole_size,
      :sentinel_delay,
      :nightly_aggregate_enabled, :nightly_aggregate_time, :nightly_aggregate_notification_target,
      :transport_modes_as_json,
      workbenches_attributes: [
        :id,
        :locked_referential_to_aggregate_id,
        compliance_control_set_ids: @workgroup&.compliance_control_sets_by_workgroup&.keys
      ],
      compliance_control_set_ids: Workgroup.workgroup_compliance_control_sets
    )
  end

  def resource
    @workgroup ||= if params[:id]
      current_organisation.workgroups.find(params[:id]).decorate
    else
      current_organisation.workgroups.build
    end
  end

  def collection
    @workgroups ||= begin
      scope = current_organisation.workgroups
      @q = scope.ransack(params[:q])

      workgroups = @q.result(:distinct => true)

      if params[:sort] == 'owner'
        workgroups = workgroups.joins(:owner).select('workgroups.*, organisations.name').order('organisations.name ' + sort_direction)
      else
        workgroups.order('name ' + sort_direction)
      end
      workgroups.paginate(:page => params[:page])
    end
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end
end
