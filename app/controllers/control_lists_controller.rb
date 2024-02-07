# frozen_string_literal: true

class ControlListsController < Chouette::WorkbenchController
  include ApplicationHelper

  defaults resource_class: Control::List, collection_name: :control_lists_shared_with_workgroup

  before_action :decorate_control_list, only: %i[show new edit]
  after_action :decorate_control_list, only: %i[create update]

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(page: 1) if collection.out_of_bounds?
        @control_lists = collection
      end
    end
  end

  protected

  alias control_list resource

  def collection
    get_collection_ivar ||
    set_collection_ivar(
      ControlListDecorator.decorate(
        end_of_association_chain.paginate(
          page: params[:page],
          per_page: 30
        ),
        context: { workbench: workbench }
      )
    )
  end

  private

  def decorate_control_list
    object = begin
      control_list
    rescue StandardError
      build_resource
    end
    @control_list = ControlListDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def control_params
    control_options = %i[id name position type code criticity comments control_list_id _destroy]

    control_options += Control.available.flat_map { |n| n.options.keys }

    control_options
  end

  def control_context_params
    control_context_options = %i[id name type comment _destroy]
    control_context_options += Control::Context.available.flat_map { |n| n.options.keys }
    # TODO : Should be fixed and use internal method in each context
    control_context_options.delete(:line_ids)
    control_context_options.push({ line_ids: [] })

    control_context_options.push(controls_attributes: control_params)

    control_context_options
  end

  def control_list_params
    params.require(:control_list).permit(
      :name,
      :comments,
      :shared,
      :created_at,
      :updated_at,
      controls_attributes: control_params,
      control_contexts_attributes: control_context_params
    ).with_defaults(workbench_id: workbench.id)
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
