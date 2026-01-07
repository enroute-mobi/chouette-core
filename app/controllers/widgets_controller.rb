# frozen_string_literal: true

class WidgetsController < ApplicationController
  before_action :find_widget

  def update
    if @widget.update(widget_params)
      render json: { success: true, widget: @widget }
    else
      render json: { success: false, errors: @widget.errors }, status: :unprocessable_entity
    end
  end

  private

  def find_widget
    @widget = Widget.joins(dashboard: :workbench)
                   .find_by(
                     'widgets.id = ? AND dashboards.id = ? AND workbenches.id = ?',
                     params[:id],
                     params[:dashboard_id],
                     params[:workbench_id]
                   )
    
    unless @widget
      render json: { error: 'Widget not found' }, status: :not_found
    end
  end

  def widget_params
    params.require(:widget).permit(:x, :y, :width, :height)
  end
end
