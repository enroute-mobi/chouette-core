module IevInterfaces
  extend ActiveSupport::Concern

  included do
    before_action(only: [:index]) { set_date_time_params("started_at", DateTime) }
    before_action :ransack_status_params, only: [:index]
    respond_to :html
    helper_method :collection_name, :index_model, :parent
  end

  def show
    show! do
      instance_variable_set "@#{collection_name.singularize}", resource.decorate(context: {
        workbench: workbench || workgroup.workbenches.find_by(organisation_id: current_organisation.id)
      })
    end
  end

  def create
    create! { [parent, resource] }
  end

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
        @contextual_cols = []
        if workbench
          @contextual_cols << TableBuilderHelper::Column.new(key: :creator, attribute: 'creator')
        else
          @contextual_cols << TableBuilderHelper::Column.new(
            key: :workbench,
            name: Organisation.ts.capitalize,
            attribute: Proc.new { |n| n.workbench.organisation.name },
            link_to: lambda do |import|
              policy(import.workbench).show? ? import.workbench : nil
            end
          )
        end
        collection = decorate_collection(collection)
      }
    end
  end

  protected

  def parent
    @parent ||= workgroup || workbench
  end

  def workbench
    return unless params[:workbench_id]

    @workbench ||= current_organisation&.workbenches&.find(params[:workbench_id])
  end

  def workgroup
    return unless params[:workgroup_id]

    @workgroup ||= current_organisation&.workgroups&.find(params[:workgroup_id])
  end

  def collection
    scope = parent.send(collection_name)
    if index_model.name.demodulize != "Base"
      scope = scope.where(type: index_model.name)
    end
    @types = scope.select('DISTINCT(type)').map &:class

    scope = self.ransack_period_range(scope: scope, error_message:  t("#{collection_name}.filters.error_period_filter"), query: :where_started_at_in)

    @q = scope.ransack(params[:q])

    unless instance_variable_get "@#{collection_name}"
      coll = @q.result
      coll = if sort_column && sort_direction
        if sort_column == :workbench
          coll.joins(workbench: :organisation).order('organisations.name ' + sort_direction)
        else
          coll.order(sort_column + ' ' + sort_direction)
        end
      else
        coll.order(:name)
      end
      coll = coll.paginate(page: params[:page], per_page: 10)
      instance_variable_set "@#{collection_name}", decorate_collection(coll)
    end
    instance_variable_get "@#{collection_name}"
  end

  private
  def ransack_status_params
    if params[:q]
      return params[:q].delete(:status_eq_any) if params[:q][:status_eq_any].empty? || ( (resource_class.status.values & params[:q][:status_eq_any]).length >= 4 )
      params[:q][:status_eq_any].push("new", "running") if params[:q][:status_eq_any].include?("pending")
      params[:q][:status_eq_any].push("aborted", "canceled") if params[:q][:status_eq_any].include?("failed")
    end
  end

  def sort_column
    return params[:sort] if parent.imports.column_names.include?(params[:sort])
    return :workbench if params[:sort] == 'workbench'

    'created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
