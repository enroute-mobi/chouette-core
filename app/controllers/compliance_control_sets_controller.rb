class ComplianceControlSetsController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceControlSet
  include RansackDateFilter
  before_action(only: [:index]) { set_date_time_params("updated_at", DateTime) }
  respond_to :html

  def index
    index! do |format|
      format.html {
        @compliance_control_sets = decorate_compliance_control_sets(@compliance_control_sets)
      }
    end
  end

  def show
    show! do |format|
      # But now nobody is aware anymore that `format.html` passes a parameter into the block
      format.html { show_for_html }
      format.json { send_data resource.export.to_json, filename: "#{resource.name.underscore}.json" }
    end
  end


  def clone
    ComplianceControlSetCloner.new.copy(params[:id], current_organisation.id)
    flash[:notice] = I18n.t("compliance_control_sets.errors.operation_in_progress")
    redirect_to(compliance_control_sets_path)
  end

  def create
    @compliance_control_set = ComplianceControlSet.new(compliance_control_set_params)
    @compliance_control_set.organisation = current_organisation
    create!
  end

  protected

  def end_of_association_chain
    assigned_to_my_workbenches = current_organisation.workbenches.map{|w| (w.owner_compliance_control_set_ids || {}).values}.flatten.uniq.select(&:present?)
    ComplianceControlSet.where("compliance_control_sets.organisation_id = ? OR compliance_control_sets.id IN (?)", current_organisation.id, assigned_to_my_workbenches)
  end

  private

  def collection
    @compliance_control_sets ||= begin
      scope = end_of_association_chain.all
      scope = scope.assigned_to_slots(current_organisation, params[:q].try(:[], :assigned_to_slots))
      scope = self.ransack_period_range(scope: scope, error_message: t('imports.filters.error_period_filter'), query: :where_updated_at_between)
      @q_for_form = scope.ransack(params[:q])
      compliance_control_sets = @q_for_form.result
      compliance_control_sets = joins_with_associated_objects(compliance_control_sets).order(Arel.sql(sort_column + ' ' + sort_direction)) if sort_column && sort_direction
      compliance_control_sets = compliance_control_sets.paginate(page: params[:page], per_page: 30)
    end

  end

  def decorate_compliance_control_sets(compliance_control_sets)
    ComplianceControlSetDecorator.decorate(compliance_control_sets)
  end

  def decorate_compliance_controls(compliance_controls)
    ComplianceControlDecorator.decorate(compliance_controls)
  end

  def compliance_control_set_params
    params.require(:compliance_control_set).permit(:name, :import_file)
  end

  def show_for_html
    @q_controls_form        = @compliance_control_set.compliance_controls.ransack(params[:q])
    @compliance_control_set = @compliance_control_set.decorate
    compliance_controls    =
      decorate_compliance_controls( @q_controls_form.result)
      .group_by(&:compliance_control_block)
    @direct_compliance_controls        = compliance_controls.delete nil
    @blocks_to_compliance_controls_map = compliance_controls
  end

  def sort_column
    case params[:sort]
      when 'name' then 'lower(compliance_control_sets.name)'
      when 'owner_jdc' then 'lower(organisations.name)'
      when 'control_numbers' then 'COUNT(compliance_controls.id)'
      else
        ComplianceControlSet.column_names.include?(params[:sort]) ? params[:sort] : 'lower(compliance_control_sets.name)'
    end
  end

  def joins_with_associated_objects(collection)

    # dont know if this is the right way to do it but since we need to join table deoending of the params
    # it was to avoid loading associated objects if we don't need them
    case params[:sort]
      when 'owner_jdc'
        collection.joins("LEFT JOIN organisations ON compliance_control_sets.organisation_id = organisations.id")
      when 'control_numbers'
        collection.joins("LEFT JOIN compliance_controls ON compliance_controls.compliance_control_set_id = compliance_control_sets.id").group(:id)
      else
        collection
    end
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end
end
