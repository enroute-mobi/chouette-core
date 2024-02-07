# frozen_string_literal: true

class TimeTablesController < Chouette::ReferentialController
  include TimeTablesHelper
  include RansackDateFilter
  before_action(only: [:index]) { set_date_time_params("bounding_dates", Date) }
  defaults :resource_class => Chouette::TimeTable
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  def show
    show! do
      @year = params[:year] ? params[:year].to_i : @time_table.presenter.default_year
      @time_table = @time_table.decorate(context: {
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
        redirect_to referential_time_table_path(@referential, @time_table)
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
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

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
    redirect_to referential_time_table_path @referential, @time_table
  end

  protected

  def collection
    scope = select_time_tables
    scope = self.ransack_period_range(scope: scope, error_message: t('referentials.errors.validity_period'), query: :overlapping)
    @q = scope.ransack(params[:q])

    @time_tables ||= begin
      time_tables = @q.result(:distinct => true)
      sort_column
      if sort_column == "bounding_dates"
        time_tables = @q.result(:distinct => false).paginate(page: params[:page], per_page: 10)
        ids = time_tables.pluck(:id).uniq
        query = """
        WITH time_tables_dates AS(
        SELECT time_tables.id, time_table_dates.date FROM time_tables
        LEFT JOIN time_table_dates ON time_table_dates.time_table_id = time_tables.id
        WHERE time_table_dates.in_out IS NULL OR time_table_dates.in_out = 't'
        UNION
        SELECT time_tables.id, time_table_periods.period_start FROM time_tables
        LEFT JOIN time_table_periods ON time_table_periods.time_table_id = time_tables.id
        )
        SELECT time_tables.id, MIN(time_tables_dates.date) AS min_date FROM time_tables
        INNER JOIN time_tables_dates ON time_tables_dates.id = time_tables.id
        WHERE time_tables.id IN (#{ids.map(&:to_s).join(',')})
        GROUP BY time_tables.id
        ORDER BY min_date #{sort_direction}
  """

        ordered_ids =  ActiveRecord::Base.connection.exec_query(query).map {|r| r["id"]}
        order_by = ["CASE"]
        ordered_ids.each_with_index do |id, index|
          order_by << "WHEN time_tables.id='#{id}' THEN #{index}"
        end
        order_by << "END"
        time_tables = time_tables.order(order_by.join(" "))
      elsif sort_column == "vehicle_journeys_count"
        time_tables = time_tables.joins("LEFT JOIN time_tables_vehicle_journeys ON time_tables_vehicle_journeys.time_table_id = time_tables.id LEFT JOIN vehicle_journeys ON vehicle_journeys.id = time_tables_vehicle_journeys.vehicle_journey_id")\
          .group("time_tables.id").select('time_tables.*, COUNT(vehicle_journeys.id) as vehicle_journeys_count').order("#{sort_column} #{sort_direction}")
      elsif sort_column == "calendar"
        time_tables = time_tables.includes(:calendar).order("calendars.name #{sort_direction}")
      else
        time_tables = time_tables.order("#{sort_column} #{sort_direction}")
      end
      time_tables = time_tables.paginate(page: params[:page], per_page: 10)
      time_tables
    end
  end

  def select_time_tables
    if params[:route_id]
      referential.time_tables.joins(vehicle_journeys: :route).where( "routes.id IN (#{params[:route_id]})")
   else
      referential.time_tables
   end
  end

  def resource_url(time_table = nil)
    referential_time_table_path(referential, time_table || resource)
  end

  def collection_url
    referential_time_tables_path(referential)
  end

  private

  def sort_column
    @@valid_cols ||= begin
      valid_cols = %w(id color comment updated_at)
      valid_cols << "bounding_dates"
      valid_cols << "vehicle_journeys_count"
      valid_cols << "calendar"
      valid_cols
    end
    @@valid_cols.include?(params[:sort]) ? params[:sort] : 'comment'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def duplicate_source
    from_id = time_table_params['created_from_id']
    Chouette::TimeTable.find(from_id) if from_id
  end

  def decorate_time_tables(time_tables)
    TimeTableDecorator.decorate(
      time_tables,
      context: {
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

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
