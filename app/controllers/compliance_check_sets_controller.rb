class ComplianceCheckSetsController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceCheckSet
  include RansackDateFilter
  before_action(only: [:index]) { set_date_time_params("created_at", DateTime) }
  respond_to :html
  helper_method :parent

  def index
    index! do |format|
      scope = self.ransack_period_range(scope: @compliance_check_sets.joins(:compliance_control_set), error_message: t('compliance_check_sets.filters.error_period_filter'), query: :where_created_at_between)
      scope = joins_with_associated_objects(scope).order(sort_column + ' ' + sort_direction) if sort_column && sort_direction
      @q_for_form = scope.ransack(params[:q])
      format.html {
        @compliance_check_sets = ComplianceCheckSetDecorator.decorate(
          @q_for_form.result.paginate(page: params[:page], per_page: 30)
        )
      }
    end
  end

  def show
    show! do
      @compliance_check_set = @compliance_check_set.decorate
    end
  end

  def executed
    show! do |format|
      # But now nobody is aware anymore that `format.html` passes a parameter into the block
      format.html { executed_for_html }
    end
  end

  def sort_column
    if params[:sort] == "compliance_control_set"
      'lower(compliance_control_sets.name)'
    elsif params[:sort] == "associated_object"
      'lower(referentials.name)'
    else
      ComplianceCheckSet.column_names.include?(params[:sort]) ? params[:sort] : 'compliance_check_sets.created_at'
    end
  end

  def joins_with_associated_objects(collection)
    if params[:sort] == "associated_object"
      collection.joins('LEFT JOIN referentials ON compliance_check_sets.referential_id = referentials.id')
    else
      collection
    end
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'desc'
  end

  private

  # Fetch the objects, depending on the parent, either a workbench or a workgroup
  def end_of_association_chain
    parent.compliance_check_sets
  end

  def parent
    @parent ||= if params[:workgroup_id]
      workgroup = current_organisation.workgroups.find params[:workgroup_id]
      @workbench = workgroup.workbenches.find_by(organisation_id: current_organisation)
      workgroup
    else
      @workbench = current_organisation.workbenches.find params[:workbench_id]
    end
  end

  # Action Implementation
  # ---------------------

  def executed_for_html
    @q_checks_form        = @compliance_check_set.compliance_checks.ransack(params[:q])
    @compliance_check_set = @compliance_check_set.decorate
    compliance_checks = @q_checks_form.result
      .group_by(&:compliance_check_block)
    @direct_compliance_checks        = compliance_checks.delete nil
    @blocks_to_compliance_checks_map = compliance_checks
  end
end
