# frozen_string_literal: true

class SequencesController < Chouette::WorkbenchController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Sequence

  def index
    index! do |format|
      format.html do
        @sequences = SequenceDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias sequence resource

  def scope
    @scope ||= parent.sequences
  end

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
    )
  end

  # def search
  #   @search ||= Search::Sequence.from_params(params, workgroup: workbench.workgroup)
  # end

  # def collection
  #   @collection ||= search.search scope
  # end

  def collection
    @sequences = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def sequence_params
    params.require(:sequence).permit(
      :name,
      :sequence_type,
      :description,
      :range_start,
      :range_end
    )
  end
end
