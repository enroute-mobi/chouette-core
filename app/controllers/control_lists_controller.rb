class ControlListsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Control::List

  before_action :decorate_control_list, only: %i[show new edit]
  after_action :decorate_control_list, only: %i[create update]

  before_action :init_facade, only: %i[show new edit]
  after_action :init_facade, only: %i[create update]

  before_action :control_list_params, only: [:create, :update]

  belongs_to :workbench

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @control_lists = ControlListDecorator.decorate(
          @control_lists,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def fetch_object_html
    render json: { html: Operations::RenderPartial.call(object_html_params) }
  end

  protected

  alias control_list resource
  alias workbench parent

  def collection
    @control_lists = parent.control_lists.paginate(page: params[:page], per_page: 30)
  end

  private

  def init_facade
    object = control_list rescue Control::List.new(workbench: workbench)
    @facade ||= ControlListFacade.new(object, helpers)
  end

  alias facade init_facade

  helper_method :facade

  def decorate_control_list
    object = control_list rescue build_resource
    @control_list = ControlListDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def object_html_params
    params.require(:html).tap do |html_params|
      html_params[:template] = helpers
      html_params[:resource] = html_params[:type].constantize.new
      html_params[:workbench] = workbench
      html_params[:parent_klass] = Control::List
    end
  end

  def control_params
    control_options = %i[id name position type code criticity comments control_list_id _destroy]

    control_options += Control::Base.descendants.flat_map { |n| n.options.keys }
    
    control_options
  end

  def control_context_params
    control_context_options = %i[id name type comment _destroy]
    control_context_options += Control::Context.descendants.flat_map { |n| n.options.keys }

    control_context_options.push(controls_attributes: control_params)

    control_context_options
  end

  def control_list_params
    params.require(:control_list).permit(
      :name,
      :comments,
      :created_at,
      :updated_at,
      controls_attributes: control_params,
      control_contexts_attributes: control_context_params
    ).with_defaults(workbench_id: parent.id)
  end
end
