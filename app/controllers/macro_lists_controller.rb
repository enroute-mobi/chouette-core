class MacroListsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Macro::List

  before_action :macro_list_params, only: [:create, :update]

  belongs_to :workbench

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @macro_lists = MacroListDecorator.decorate(
          @macro_lists,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def new
    @macro_list = MacroListDecorator.decorate Macro::List.new, context: { workbench: @workbench }
    new!
  end

  # def show
  #   show! do |format|
  #     @macro_list = MacroListDecorator.decorate context: { workbench: @workbench }
  #   end
  # end

  def update
    update! do
      if macro_list_params[:macro_list_ids]
        workbench_macro_lists_path @workbench, @macro_list
      else
        workbench_macro_list_path @workbench, @macro_list
      end
    end
  end

  protected

  alias_method :macro_list, :resource
  alias_method :workbench, :parent

  def collection
    @macro_lists = parent.macro_lists.paginate(page: params[:page], per_page: 30)
  end

  private

  # def sort_column
  #   params[:sort].presence || 'departure'
  # end

  # def sort_direction
  #   %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  # end

  def macro_list_params
    params.require(:macro_list).permit(
      :workbench_id,
      :name,
      :comments,
      :created_at,
      :updated_at,
    )
  end
end
