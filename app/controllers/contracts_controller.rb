# frozen_string_literal: true

class ContractsController < Chouette::WorkbenchController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Contract

  respond_to :html

  def index
    index! do |format|
      format.html do
        @contracts = ContractDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias contract resource

  def scope
    @scope ||= parent.contracts
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
  #   @search ||= Search::Contract.from_params(params, workgroup: workbench.workgroup)
  # end

  # def collection
  #   @collection ||= search.search scope
  # end

  def collection
    @contracts = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def contract_params
    params.require(:contract).permit(
      :name,
      :company_id,
      lines: [],
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
