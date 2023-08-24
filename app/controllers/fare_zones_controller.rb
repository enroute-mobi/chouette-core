class FareZonesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Fare::Zone

  before_action :decorate_fare_zone, only: %i[show new edit]
  after_action :decorate_fare_zone, only: %i[create update]

  belongs_to :workbench

  def index
    index! do |format|
      format.html do
        @fare_zones = FareZoneDecorator.decorate(
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

  def scope
    @scope ||= workbench.fare_zones
  end

  def decorate_fare_zone
    object = document_type rescue build_resource
    @fare_zone = FareZoneDecorator.decorate(
      object,
      context: {
        workbench: @workbench
      }
    )
  end

  # def resource
  #   get_resource_ivar || set_resource_ivar(scope.find_by_id(params[:id]).decorate(context: { workbench: @workbench }))
  # end

  # def build_resource
  #   get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_build,
  #                                                                        *resource_params).decorate(context: { workbench: @workbench }))
  # end

  # def search
  #   @search ||= Search::Document.new(scope, params, workgroup: workbench.workgroup)
  # end
  # delegate :collection, to: :search

  private

  def fare_zone_params
    params.require(:fare_zone).permit(
      :name,
      :fare_provider_id,
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
