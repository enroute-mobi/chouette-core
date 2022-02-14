class MacroListsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Macro::List

  before_action :decorate_macro_list, only: %i[show new edit]
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

  def create
    create! do |_success, failure|
      failure.html do
        @macro_list = MacroListDecorator.decorate(macro_list, context: { workbench: @workbench })

        render 'new'
      end
    end
  end

  def update
     update! do |_success, failure|
      failure.html do
        @macro_list = MacroListDecorator.decorate(macro_list, context: { workbench: @workbench })

        render 'edit'
      end
    end
  end

  def fetch_macro_html
    render json: { html: RenderMacroPartial.call(macro_html_params) }
  end

  protected

  alias macro_list resource
  alias workbench parent

  def collection
    @macro_lists = parent.macro_lists.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_macro_list
    object = macro_list rescue build_resource
    @macro_list = MacroListDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  # def sort_column
  #   params[:sort].presence || 'departure'
  # end

  # def sort_direction
  #   %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  # end

  def macro_html_params
    params.require(:html).permit(
      :id,
      :type,
    ).with_defaults(
      template: helpers
    )
  end

  def macro_list_params
    macro_options = %i[id name position type comments macro_list_id _destroy]

    macro_options += Macro::Base.descendants.map do |t|
      t.options.map do |key, value|
        # To accept an array value directly in params, a permit({key: []}) is required instead of just permit(:key)
        value.try(:[], :type)&.equal?(:array) ? Hash[key => []] : key
      end
    end.flatten

    params.require(:macro_list).permit(
      :name,
      :comments,
      :created_at,
      :updated_at,
      macros_attributes: macro_options
    ).with_defaults(workbench_id: parent.id)
  end
end
