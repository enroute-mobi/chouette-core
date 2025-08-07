# frozen_string_literal: true

class TagsController < Chouette::WorkbenchController
  defaults resource_class: Tag

  def index
    index! do |format|
      format.html do
        @tags = TagDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias tag resource

  def scope
    @scope ||= workbench.tags
  end

  def collection
    @tags = scope.paginate(page: params[:page], per_page: 30)
  end

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench }))
  end

  def tag_params
    params.require(:tag).permit(:name, :color, :description)
  end
end
