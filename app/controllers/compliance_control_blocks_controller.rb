class ComplianceControlBlocksController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceControlBlock
  belongs_to :compliance_control_set
  actions :all, :except => [:show, :index]

  after_action :check_duplicate, only: :create

  def check_duplicate
    unless @compliance_control_block.errors[:duplicate].empty?
      flash[:error] = @compliance_control_block.errors[:duplicate].first
    end
  end

  private

  def compliance_control_block_params
    params.require(:compliance_control_block).permit(:transport_mode, :transport_submode)
  end

end
