# frozen_string_literal: true

class DashboardsController < Chouette::WorkbenchController
  defaults resource_class: Dashboard

  skip_before_action :authorize_resource, only: [:edit_layout]

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

  def show
    show! do |format|
      format.html
      format.json { render json: @dashboard.widgets.select(:id, :x, :y, :width, :height) }
    end
  end

  def edit_layout
  @dashboard = Dashboard.find(params[:id])
  @workbench = Workbench.find(params[:workbench_id])
  render 'edit_layout'
  end

  def widget_positions
    render json: @dashboard.widgets.select(:id, :x, :y, :width, :height)
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