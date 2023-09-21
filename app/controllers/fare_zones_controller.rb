class FareZonesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Fare::Zone

  belongs_to :workbench

  def index
    index! do |format|
      format.html do
        @fare_zones = Fare::ZoneDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  protected

  alias fare_zone resource
  alias workbench parent

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench }))
  end

  private

  def fare_zone_params
    params.require(:fare_zone).permit(
      :name,
      :fare_provider_id,
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
