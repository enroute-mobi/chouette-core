# frozen_string_literal: true

class CalendarsController < Chouette::WorkbenchController
  defaults resource_class: Calendar

  respond_to :html
  respond_to :json, only: :show
  respond_to :js, only: :index

  def index
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

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

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::Calendar)
  end

  protected

  alias workbench parent
  helper_method :workbench

  def resource
    @calendar ||= workbench.calendars_with_shared.find_by(id: params[:id]) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def build_resource
    super.tap do |calendar|
      calendar.workbench = workbench
    end
  end

  def scope
    parent.calendars
  end

  def search
    @search ||= ::Search::Calendar.from_params(params, workbench: workbench)
  end

  def collection
    @calendars ||= search.search(scope) # rubocop:disable Naming/MemoizedInstanceVariableName
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
end
