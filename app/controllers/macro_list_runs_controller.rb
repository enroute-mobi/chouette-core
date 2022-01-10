class MacroListRunsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Macro::List::Run

  before_action :decorate_macro_list_run, only: %i[show new edit]

	belongs_to :workbench
	belongs_to :macro_list, optional: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(:page => 1) if collection.out_of_bounds?

        @macro_list_runs = MacroListRunDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def create
		@macro_list_run = Macro::List
			.find(params.dig(:macro_list_run, :original_macro_list_id))
			.build_run(macro_list_run_attributes_params)
	
    create! do |success, failure|
      failure.html do
        @macro_list_run = MacroListRunDecorator.decorate(@macro_list_run, context: { workbench: workbench })

        render 'new'
      end

			success.html { redirect_to workbench_macro_list_run_url(workbench, @macro_list_run) }
    end
  end

  protected

  alias_method :macro_list, :parent
  alias_method :macro_list_run, :resource

  def collection
    workbench.macro_list_runs.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_macro_list_run
    object = macro_list_run rescue build_resource 
    @macro_list_run = MacroListRunDecorator.decorate(
      object,
      context: {
        workbench: workbench,
				macro_list: macro_list
      }
    )
  end

	def workbench
		@workbench ||= Workbench.find(params[:workbench_id])
	end

	def macro_list_run_attributes_params
		params
			.require(:macro_list_run)
			.require(:attributes)
			.permit(:referential_id)
			.with_defaults(creator: current_user.name)
			.to_h
			.delete_if { |k,v| v.blank? }
	end
end
