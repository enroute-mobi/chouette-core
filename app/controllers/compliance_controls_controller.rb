class ComplianceControlsController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceControl
  belongs_to :compliance_control_set
  actions :all, :except => [:index]

  def show
    show! do
      @compliance_control = @compliance_control.decorate
    end
  end

  def new
    if params[:sti_class].blank?
      flash[:notice] = I18n.t("compliance_controls.errors.mandatory_control_type")
      redirect_to(action: :select_type)
    end
    new! do
      load_blocks
    end
  end

  def create
    create! do |success, failure|
      success.html { redirect_to compliance_control_set_path(parent) }
      failure.html { render( :action => 'new' ) }
    end
  end

  def edit
    edit! do
      load_blocks
    end
  end

  def update
    update! do |success, failure|
      success.html { redirect_to compliance_control_set_path(parent) }
      failure.html { render( :action => 'edit' ) }
    end
  end

  protected

  alias_method :compliance_control_set, :parent
  alias_method :compliance_control, :resource

  def build_resource
    get_resource_ivar || begin
      res = set_resource_ivar(compliance_control_class.send(:new, *resource_params))
      res.iev_enabled_check = compliance_control_class.iev_enabled_check
      res
    end
  end

  private

  def begin_of_association_chain
    nil
  end

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

  def load_blocks
    @available_blocks = parent.compliance_control_blocks
    if resource.iev_enabled_check?
      @available_blocks = @available_blocks.select { |b| b.accept_iev_controls? }
    end
  end
end
