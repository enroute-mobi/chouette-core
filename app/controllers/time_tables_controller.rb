class TimeTablesController < ChouetteController
  include TimeTablesHelper
  defaults :resource_class => Chouette::TimeTable
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  belongs_to :referential

  include PolicyChecker

  def show
    @year = params[:year] ? params[:year].to_i : Date.today.cwyear
    @time_table_combination = TimeTableCombination.new
    show! do
      build_breadcrumb :show
    end
  end

  def month
    @date = params['date'] ? Date.parse(params['date']) : Date.today
    @time_table = resource
  end

  def new
    @autocomplete_items = ActsAsTaggableOn::Tag.all
    new! do
      build_breadcrumb :new
    end
  end

  def create
    tt_params = time_table_params
    if tt_params[:calendar_id]
      %i(monday tuesday wednesday thursday friday saturday sunday).map { |d| tt_params[d] = true }
      calendar = current_organisation.calendars.find_by_id(tt_params[:calendar_id])
      tt_params[:calendar_id] = nil if tt_params.has_key?(:dates_attributes) || tt_params.has_key?(:periods_attributes)
    end
    @time_table = Chouette::TimeTable.new(tt_params)
    if calendar
      calendar.dates.each_with_index do |date, i|
        @time_table.dates << Chouette::TimeTableDate.new(date: date, position: i)
      end
      calendar.date_ranges.each_with_index do |date_range, i|
        @time_table.periods << Chouette::TimeTablePeriod.new(period_start: date_range.begin, period_end: date_range.end, position: i)
      end
    end
    create!
  end

  def edit
    edit! do
      build_breadcrumb :edit
      @autocomplete_items = ActsAsTaggableOn::Tag.all
    end
  end

  def update
    state  = JSON.parse request.raw_post
    respond_to do |format|
      format.json { render json: state, status: state['errors'] ? :unprocessable_entity : :ok }
    end
  end

  def index
    request.format.kml? ? @per_page = nil : @per_page = 12

    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
        build_breadcrumb :index
      }
    end
  end

  def duplicate
    @time_table = Chouette::TimeTable.find params[:id]
    # prepare breadcrumb before prepare data for new timetable
    build_breadcrumb :edit
    @time_table = @time_table.duplicate
    render :new
  end

  def tags
    @tags = ActsAsTaggableOn::Tag.where("tags.name LIKE ?", "%#{params[:tag]}%")
    respond_to do |format|
      format.json { render :json => @tags.map{|t| {:id => t.id, :name => t.name }} }
    end
  end

  protected

  def collection
    scope = select_time_tables
    if params[:q] && params[:q]["tag_search"]
      tags = params[:q]["tag_search"].reject {|c| c.empty?}
      params[:q].delete("tag_search")
      scope = select_time_tables.tagged_with(tags, :wild => true, :any => true) if tags.any?
    end
    scope = ransack_periode(scope)

    @q = scope.search(params[:q])
    if sort_column && sort_direction
      @time_tables ||= @q.result(:distinct => true).order("#{sort_column} #{sort_direction}")
    else
      @time_tables ||= @q.result(:distinct => true).order(:comment)
    end
    @time_tables = @time_tables.paginate(page: params[:page], per_page: 10)
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
  # Fake ransack filter
  def ransack_periode scope
    return scope unless params[:q]
    periode = params[:q]
    return scope if periode['end_date_lteq(1i)'].empty? || periode['start_date_gteq(1i)'].empty?

    begin_range = Date.civil(periode["start_date_gteq(1i)"].to_i, periode["start_date_gteq(2i)"].to_i, periode["start_date_gteq(3i)"].to_i)
    end_range   = Date.civil(periode["end_date_lteq(1i)"].to_i, periode["end_date_lteq(2i)"].to_i, periode["end_date_lteq(3i)"].to_i)

    if begin_range > end_range
      flash.now[:error] = t('referentials.errors.validity_period')
    else
      @begin_range = begin_range
      @end_range   = end_range
    end
    scope
  end

  def sort_column
    referential.time_tables.column_names.include?(params[:sort]) ? params[:sort] : 'comment'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def time_table_params
    params.require(:time_table).permit(
      :objectid,
      :object_version,
      :creator_id,
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
      { :dates_attributes => [:date, :in_out, :id, :_destroy] },
      { :periods_attributes => [:period_start, :period_end, :_destroy, :id] },
      {tag_list: []},
      :tag_search
    )
  end
end
