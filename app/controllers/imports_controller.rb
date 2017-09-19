class ImportsController < BreadcrumbController
  include PolicyChecker
  skip_before_action :authenticate_user!, only: [:download]
  defaults resource_class: Import, collection_name: 'imports', instance_name: 'import'
  before_action :ransack_started_at_params, only: [:index]
  before_action :ransack_status_params, only: [:index]
  respond_to :html
  belongs_to :workbench

  def show
    show! do
      @import = @import.decorate(context: {
        workbench: @workbench
      })

      build_breadcrumb :show
    end
  end

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @imports = decorate_imports(@imports)
      }

      build_breadcrumb :index
    end
  end

  def new
    new! do
      build_breadcrumb :new
    end
  end

  def download
    if params[:token] == resource.token_download
      send_file resource.file.path
    else
      user_not_authorized
    end
  end

  protected
  def collection
    scope = parent.imports.where(type: "WorkbenchImport")
    scope = ransack_period scope

    @q = scope.search(params[:q])

    if sort_column && sort_direction
      @imports ||= @q.result(distinct: true).order(sort_column + ' ' + sort_direction).paginate(page: params[:page], per_page: 10)
    else
      @imports ||= @q.result(distinct: true).order(:name).paginate(page: params[:page], per_page: 10)
    end
  end

  private

  def ransack_started_at_params
    start_date = []
    end_date = []

    if params[:q] && params[:q][:started_at] && !params[:q][:started_at].has_value?(nil) && !params[:q][:started_at].has_value?("")
      [1, 2, 3].each do |key|
        start_date <<  params[:q][:started_at]["begin(#{key}i)"].to_i
        end_date <<  params[:q][:started_at]["end(#{key}i)"].to_i
      end
      params[:q].delete([:started_at])
      @begin_range = DateTime.new(*start_date,0,0,0) rescue nil
      @end_range = DateTime.new(*end_date,23,59,59) rescue nil
    end
  end

  # Fake ransack filter
  def ransack_period scope
    return scope unless !!@begin_range && !!@end_range

    if @begin_range > @end_range
      flash.now[:error] = t('imports.filters.error_period_filter')
    else
      scope = scope.where_started_at_between(@begin_range, @end_range)
    end
    scope
  end

  def ransack_status_params
    if params[:q]
      binding.pry
      return params[:q].delete(:status_eq_any) if params[:q][:status_eq_any].empty? || ( (Import.status.values & params[:q][:status_eq_any]).length >= 4 )
      params[:q][:status_eq_any].push("new", "running") if params[:q][:status_eq_any].include?("pending")
      params[:q][:status_eq_any].push("aborted", "canceled") if params[:q][:status_eq_any].include?("failed")
    end
  end

  def build_resource
    @import ||= WorkbenchImport.new(*resource_params) do |import|
      import.workbench = parent
      import.creator   = current_user.name
    end
  end

  def import_params
    params.require(:import).permit(
      :name,
      :file,
      :type,
      :referential_id
    )
  end

  def sort_column
    parent.imports.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def decorate_imports(imports)
    ModelDecorator.decorate(
      imports,
      with: ImportDecorator,
      context: {
        workbench: @workbench
      }
    )
  end
end
