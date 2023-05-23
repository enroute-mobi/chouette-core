module Redirect
  class TimeTablesController < BaseController
    include ReferentialSupport

    def time_table
      Chouette::TimeTable.find(params[:id])
    end

    def show
      redirect_to referential_time_table_path referential, time_table
    end
  end
end
