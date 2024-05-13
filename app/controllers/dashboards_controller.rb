# frozen_string_literal: true

# If you changed the default Dashboard implementation (see Dashboard),
# this controller will use a custom partial like
# custom/dashboards/_dashboard.html.slim for Custom::Dashboard
#
class DashboardsController < Chouette::UserController
  respond_to :html, only: [:show]

  def show
    @dashboard = Dashboard.create self
    @workbenches = current_user.workbenches
  end
end
