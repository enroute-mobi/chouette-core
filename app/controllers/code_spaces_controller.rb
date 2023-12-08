# frozen_string_literal: true

class CodeSpacesController < Chouette::WorkgroupController
  # required because of page_title helper :"(
  defaults resource_class: CodeSpace

  belongs_to :workgroup

  protected

  def collection
    get_collection_ivar || set_collection_ivar(CodeSpaceDecorator.decorate(super.order(:short_name).paginate(page: params[:page]), context: { workgroup: @workgroup }))
  end

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workgroup: @workgroup }))
  end

  def code_space_params
    params.require(:code_space).permit(:name, :short_name, :description)
  end

  # def build_resource
  #   get_resource_ivar || super.tap do |code_space|

  #   end
  # end

end
