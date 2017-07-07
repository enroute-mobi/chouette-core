class WorkbenchesController < BreadcrumbController
  before_action :query_params, only: [:show]

  defaults resource_class: Workbench
  respond_to :html, only: [:show]

  def show
    scope = resource.all_referentials
    scope = ransack_associated_lines(scope)
    scope = ransack_period(scope)
    scope = ransack_status(scope)

    @q_for_form   = scope.ransack(params[:q])
    @q_for_result = scope.ransack(ransack_params)
    @wbench_refs  = sort_result(@q_for_result.result).paginate(page: params[:page], per_page: 30)
    @wbench_refs  = ModelDecorator.decorate(@wbench_refs, with: ReferentialDecorator)

    show! do
      build_breadcrumb :show
    end
  end

  def delete_referentials
    referentials = resource.referentials.where(id: params[:referentials])
    referentials.each do |referential|
      ReferentialDestroyWorker.perform_async(referential.id)
      referential.update_attribute(:ready, false)
    end
    flash[:notice] = t('notice.referentials.deleted')
    redirect_to resource
  end

  private
  def resource
    require 'pry'
    binding.pry
    @workbench = current_organisation.workbenches.find params[:id]
  end

  def sort_result collection
    col = (Workbench.find(params[:id]).referentials.column_names + %w{lines validity_period}).include?(params[:sort]) ? params[:sort] : 'name'
    dir = %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'

    if ['lines', 'validity_period'].include?(col)
      collection.send("order_by_#{col}", dir)
    else
      collection.order("#{col} #{dir}")
    end
  end

  def query_params
    params[:q] ||= {}
    params[:q].delete_if { |query, value| value.blank? }
  end

  # Fake ransack filter
  def ransack_associated_lines scope
    if params[:q]['associated_lines_id_eq']
      scope = scope.include_metadatas_lines([params[:q]['associated_lines_id_eq']])
    end
    scope
  end

  # Fake ransack filter
  def ransack_period scope
    period = params[:q]['validity_period']
    return scope unless period

    begin
      if period['begin_gteq'].kind_of?(Array)
        begin_range = Date.new(*period['begin_gteq'].map(&:to_i))
        end_range   = Date.new(*period['end_lteq'].map(&:to_i))
      else
        begin_range = Date.new(period["begin_gteq(1i)"].to_i, period["begin_gteq(2i)"].to_i, period["begin_gteq(3i)"].to_i)
        end_range   = Date.new(period["end_lteq(1i)"].to_i, period["end_lteq(2i)"].to_i, period["end_lteq(3i)"].to_i)
      end
    rescue Exception => e
      return scope
    end

    if begin_range > end_range
      flash.now[:error] = t('referentials.errors.validity_period')
    else
      scope        = scope.in_periode(begin_range..end_range)
      @begin_range = begin_range
      @end_range   = end_range
    end
    scope
  end

  # Fake ransack filter
  def ransack_status scope
    archived   = !params[:q]['archived_at_not_null'].to_i.zero?
    unarchived = !params[:q]['archived_at_null'].to_i.zero?

    # Both status checked, means no filter
    return scope unless archived || unarchived
    return scope if archived && unarchived

    scope = scope.where(archived_at: nil) if unarchived
    scope = scope.where("archived_at is not null") if archived
    scope
  end

  # Ignore archived_at_not_null/archived_at_null managed by ransack_status scope
  # We clone params[:q] so we can delete fake ransack filter arguments before calling search method,
  # which will allow us to preserve params[:q] for sorting
  def ransack_params
    copy_params = params[:q].clone
    copy_params.delete('associated_lines_id_eq')
    copy_params.delete('archived_at_not_null')
    copy_params.delete('archived_at_null')
    copy_params
  end
end
