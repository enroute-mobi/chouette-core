class Api::V1::ImportsController < Api::V1::WorkbenchController
  respond_to :json, only: [:show, :index, :create]

  def create
    args = workbench_import_params.merge(creator: 'Webservice')
    @import = @current_workbench.workbench_imports.new(args)
    if @import.save
      render json: @import, status: :created
    else
      render json: { status: "error", messages: @import.errors.full_messages }
    end
  end

  def index
    render json: imports_map
  end

  def show
    @import = @current_workbench.workbench_imports.find(params[:id])
    render json: @import
  end

  private

  def imports_map
    @current_workbench.imports.collect do |import|
      {id: import.id, name: import.name, status: import.status, referential_ids: import.children.collect(&:referential_id).compact}
    end
  end

  def workbench_import_params
    permitted_keys = %i(name file)
    permitted_keys << {options: Import::Workbench.options.keys}
    params.require(:workbench_import).permit(permitted_keys)
  end
end
