# frozen_string_literal: true

class MacroListsController < Chouette::WorkbenchController
  include ApplicationHelper

  defaults resource_class: Macro::List

  before_action :decorate_macro_list, only: %i[show new edit]
  after_action :decorate_macro_list, only: %i[create update]

  before_action :macro_list_params, only: %i[create update]

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(page: 1) if collection.out_of_bounds?

        @macro_lists = MacroListDecorator.decorate(
          @macro_lists,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias macro_list resource

  def collection
    @macro_lists = parent.macro_lists.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_macro_list
    object = begin
      macro_list
    rescue StandardError
      build_resource
    end
    @macro_list = MacroListDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def macro_params
    macro_options = %i[id name position type comments macro_list_id _destroy]

    macro_options += Macro.available.flat_map { |n| n.options.keys }

    macro_options
  end

  def macro_context_params
    macro_context_options = %i[id name type comment _destroy]
    macro_context_options += Macro::Context.available.flat_map { |n| n.options.keys }

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
    ).with_defaults(workbench_id: workbench.id)
  end
end
