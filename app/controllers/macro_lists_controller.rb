class MacroListsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Macro::List

  before_action :decorate_macro_list, only: %i[show new edit]
  after_action :decorate_macro_list, only: %i[create update]

  before_action :init_presenter, only: %i[show new edit]
  after_action :init_presenter, only: %i[create update]

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

  def fetch_object_html
    render json: { html: MacroLists::RenderPartial.call(macro_html_params) }
  end

  protected

  alias macro_list resource
  alias workbench parent

  def collection
    @macro_lists = parent.macro_lists.paginate(page: params[:page], per_page: 30)
  end

  private

  def init_presenter
    @presenter ||= MacroListPresenter.new(@macro_list, helpers)
  end

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

  def macro_params
    macro_options = %i[id name position type comments macro_list_id _destroy]

    macro_options += Macro::Base.descendants.flat_map { |n| n.options.keys }
    
    macro_options
  end

  def macro_context_params
    macro_context_options = %i[id name type comments]
    macro_context_options += Macro::Context.descendants.flat_map { |n| n.options.keys }

    macro_context_options.push(macros_attributes: macro_params)

    macro_context_options
  end

  def macro_list_params
    params.require(:macro_list).permit(
      :name,
      :comments,
      :created_at,
      :updated_at,
      macros_attributes: macro_params,
      macro_contexts_attributes: macro_context_params
    ).with_defaults(workbench_id: parent.id)
  end
end
