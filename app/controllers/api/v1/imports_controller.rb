class Api::V1::ImportsController < Api::V1::WorkbenchController
  defaults resource_class: Import::Workbench, collection_name: 'workbench_imports', instance_name: 'import'

  def create
    args    = workbench_import_params.merge(creator: 'Webservice')
    @import = @current_workbench.workbench_imports.new(args)
    if @import.valid?
      create!
    else
      render json: { status: "error", messages: @import.errors.full_messages }
    end
  end

  private

  def workbench_import_params
    permitted_keys = %i(name file)
    permitted_keys << {options: Import::Workbench.options.keys}
    params.require(:workbench_import).permit(permitted_keys)
  end
end
