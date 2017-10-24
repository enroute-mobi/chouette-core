class ComplianceControlsController < BreadcrumbController
  defaults resource_class: ComplianceControl
  belongs_to :compliance_control_set
  actions :all, :except => [:show, :index]

  def select_type
    @sti_subclasses = ComplianceControl.subclasses
  end

  def new
    if params[:sti_class].blank?
      flash[:notice] = I18n.t("compliance_controls.errors.mandatory_control_type")
      redirect_to(action: :select_type)
    end
    new!
  end

  def create
    create! do |success, failure|
      success.html { redirect_to compliance_control_set_path(parent) }
      failure.html { render( :action => 'new' ) }
    end
  end

  protected

  alias_method :compliance_control_set, :parent
  alias_method :compliance_control, :resource

  def build_resource
    get_resource_ivar || set_resource_ivar(compliance_control_class.send(:new, *resource_params))
  end

  private

  def compliance_control_class
    (params[:sti_class] || params[:compliance_control][:type]).constantize
  end

  def dynamic_attributes_params
    compliance_control_class.dynamic_attributes
  end

  def compliance_control_params
    base = [:name, :code, :origin_code, :criticity, :comment, :control_attributes, :type, :compliance_control_block_id, :compliance_control_set_id]
    permitted = base + dynamic_attributes_params
    params.require(:compliance_control).permit(permitted)
  end
end
