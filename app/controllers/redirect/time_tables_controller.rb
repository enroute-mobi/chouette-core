module Redirect
  class TimeTablesController < BaseController
    include ReferentialSupport

    def time_table
      referential.time_tables.find(params[:id])
    end

    def show
      redirect_to referential_time_table_path referential, time_table
    end
  end
end
