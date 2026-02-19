# frozen_string_literal: true

class DashboardsController < Chouette::WorkbenchController
  defaults resource_class: Dashboard
  respond_to :json, only: :update

  custom_actions resource: :edit_layout

  def index
    index! do |format|
      format.html do
        @dashboards = DashboardDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  private

  alias dashboard resource

  def scope
    @scope ||= workbench.dashboards
  end

  def collection
    @collection = scope.paginate(page: params[:page], per_page: 30)
  end

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench, dashboard: dashboard }))
  end

  def dashboard_params
    params.require(:dashboard).permit(
      :name, 
      :description,
      widgets_attributes: [
        :id, 
        :name, 
        :widget_type,
        :x,
        :y, 
        :width,
        :height,
        :_destroy,
        { options: {} }
      ]
    )
  end
end