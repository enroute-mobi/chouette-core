class ComplianceControlBlocksController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceControlBlock
  belongs_to :compliance_control_set
  actions :all, except: %i[show index]

  private

  def compliance_control_block_params
    params.require(:compliance_control_block).permit(:block_kind, :transport_mode, :transport_submode, :country, :min_stop_areas_in_country)
  end

  protected

  alias_method :compliance_control_set, :parent
  helper_method :compliance_control_set

end
