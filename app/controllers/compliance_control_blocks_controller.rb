class ComplianceControlBlocksController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceControlBlock
  belongs_to :compliance_control_set
  actions :all, :except => [:show, :index]

  after_action :check_duplicate, only: [:create, :update]

  def check_duplicate
    unless @compliance_control_block.errors[:condition_attributes].empty?
      flash[:error] = @compliance_control_block.errors[:condition_attributes].join(', ')
    end
  end

  private

  def compliance_control_block_params
    params.require(:compliance_control_block).permit(:transport_mode, :transport_submode)
  end

end
