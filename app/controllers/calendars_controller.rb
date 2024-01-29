# frozen_string_literal: true

class CalendarsController < Chouette::WorkbenchController
  include PolicyChecker

  defaults resource_class: Calendar
  before_action :ransack_contains_date, only: [:index]
  respond_to :html
  respond_to :json, only: :show
  respond_to :js, only: :index

  def index
    index! do
      @calendars = @calendars.includes(:organisation)
      @calendars = decorate_calendars(@calendars)
    end
  end

  def show
    show! do
      @year = params[:year] ? params[:year].to_i : @calendar.presenter.default_year
      @calendar = @calendar.decorate(
        context: {
          workbench: workbench
        }
      )
    end
  end

  def month
    @date = params['date'] ? Date.parse(params['date']) : Date.today
    @calendar = resource
  end

  def update
    if params[:calendar]
      super
    else
      state  = JSON.parse request.raw_post
      resource.state_update state
      respond_to do |format|
        format.json { render json: state, status: state['errors'] ? :unprocessable_entity : :ok }
      end
    end
  end

  private

  def decorate_calendars(calendars)
    CalendarDecorator.decorate(
      calendars,
      context: {
        workbench: workbench
      }
    )
  end

  def calendar_params
    permitted_params = [
      :id, :name,
      {
        periods_attributes: %i[id begin end _destroy],
        date_values_attributes: %i[id value _destroy]
      }
    ]
    # CHOUETTE-3123 Alban's idea: we need an instance but cannot call #build_resource since it calls #calendar_params
    permitted_params << :shared if policy(workbench.calendars.build).share?
    params.require(:calendar).permit(*permitted_params)
  end

  def sort_results collection
    dir =  %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
    extra_cols = %w(organisation_name)
    col = (Calendar.column_names + extra_cols).include?(params[:sort]) ? params[:sort] : 'name'

    if extra_cols.include?(col)
      collection.send("order_by_#{col}", dir)
    else
      collection.order("#{col} #{dir}")
    end
  end

  protected

  alias workbench parent
  helper_method :workbench

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def resource
    @calendar ||= workbench.calendars_with_shared.find_by(id: params[:id])
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def build_resource
    super.tap do |calendar|
      calendar.workbench = workbench
    end
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def collection
    @calendars ||= begin
      scope = workbench.calendars_with_shared
      scope = shared_scope(scope)
      @q = scope.ransack(params[:q])
      calendars = sort_results(@q.result)
      calendars = calendars.paginate(page: params[:page])
      calendars
    end
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def ransack_contains_date
    date =[]
    if params[:q] && !params[:q]['contains_date(1i)'].empty?
      ['contains_date(1i)', 'contains_date(2i)', 'contains_date(3i)'].each do |key|
        date << params[:q][key].to_i
        params[:q].delete(key)
      end
      params[:q]['contains_date'] = Date.new(*date) rescue nil
    end
  end

  def shared_scope scope
    return scope unless params[:q]

    if params[:q][:shared_true] == params[:q][:shared_false]
      params[:q].delete(:shared_true)
      params[:q].delete(:shared_false)
    end

    scope
  end
end
