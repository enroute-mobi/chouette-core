# frozen_string_literal: true

class TimeTablesController < Chouette::ReferentialController
  include TimeTablesHelper
  include RansackDateFilter

  defaults resource_class: Chouette::TimeTable

  belongs_to :referential

  before_action(only: [:index]) { set_date_time_params("bounding_dates", Date) }

  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  def show
    show! do
      @year = params[:year] ? params[:year].to_i : @time_table.presenter.default_year
      @time_table = @time_table.decorate(context: {
        workbench: @workbench,
        referential: @referential
      })
      @calendar = @time_table.calendar
    end
  end

  def month
    @date = params['date'] ? Date.parse(params['date']) : Date.today
    @time_table = resource
  end

  def create
    tt_params = time_table_params
    if tt_params[:calendar_id] && tt_params[:calendar_id] != ""
      calendar = Calendar.find(tt_params[:calendar_id])
      comment = tt_params[:comment].presence
      @time_table = calendar.convert_to_time_table(comment)
      tt_params[:calendar_id] = nil if tt_params.has_key?(:dates_attributes) || tt_params.has_key?(:periods_attributes)
    end

    @time_table  ||= duplicate_source ? duplicate_source.duplicate(tt_params) : Chouette::TimeTable.new(tt_params)

    create! do |success, failure|
      success.html do
        redirect_to workbench_referential_time_table_path(current_workbench, @referential, @time_table)
      end
      failure.html { render :new }
    end
  end

  def update
    state  = JSON.parse request.raw_post
    resource.state_update state
    respond_to do |format|
      format.json { render json: state, status: state['errors'] ? :unprocessable_entity : :ok }
    end
  end

  def index
    index! do |format|
      format.html {
        @time_tables = decorate_time_tables(@time_tables)
      }

      format.js {
        @time_tables = decorate_time_tables(@time_tables)
      }
    end
  end

  def duplicate
    @time_table = Chouette::TimeTable.find params[:id]
    @time_table = @time_table.duplicate
    render :new
  end

  def actualize
    @time_table = resource
    if @time_table.calendar
      @time_table.actualize
      flash[:notice] = t('.success')
    end
    redirect_to workbench_referential_time_table_path current_workbench, @referential, @time_table
  end

  protected

  def scope
    parent.time_tables
  end

  def search
    @search ||= Search::TimeTable.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  def resource_url(time_table = nil)
    workbench_referential_time_table_path(current_workbench, referential, time_table || resource)
  end

  def collection_url
    workbench_referential_time_tables_path(current_workbench, referential)
  end

  private

  def duplicate_source
    from_id = time_table_params['created_from_id']
    Chouette::TimeTable.find(from_id) if from_id
  end

  def decorate_time_tables(time_tables)
    TimeTableDecorator.decorate(
      collection,
      context: {
        workbench: @workbench,
        referential: @referential
      }
    )
  end

  def time_table_params
    params.require(:time_table).permit(
      :objectid,
      :object_version,
      :calendar_id,
      :version, :comment, :color,
      :int_day_types,
      :monday,
      :tuesday,
      :wednesday,
      :thursday,
      :friday,
      :saturday,
      :sunday,
      :start_date,
      :end_date,
      :created_from_id,
      { :dates_attributes => [:date, :in_out, :id, :_destroy] },
      { :periods_attributes => [:period_start, :period_end, :_destroy, :id] }
    )
  end
end
