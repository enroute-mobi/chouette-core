class EntrancesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Entrance

  before_action :entrance_params, only: [:create, :update]

  belongs_to :workbench
  belongs_to :stop_area_referential, singleton: true

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @entrances = EntranceDecorator.decorate(
          @entrances,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def show
    show! do |format|
      @entrance = @entrance.decorate context: { workbench: @workbench }
    end
  end

  def update
    update! do
      if entrance_params[:entrance_ids]
        workbench_stop_area_referential_entrances_path @workbench, @entrance
      else
        workbench_stop_area_referential_entrance_path @workbench, @entrance
      end
    end
  end

  protected

  alias_method :entrance, :resource
  alias_method :stop_area_referential, :parent

  def collection
    @entrances = parent.entrances.paginate(page: params[:page], per_page: 30)
  end

  private

  def sort_column
    params[:sort].presence || 'departure'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def entrance_params
    params.require(:entrance).permit(
      :objectid,
      :stop_area_id,
      :stop_area_provider_id,
      :name,
      :short_name,
      :entry_flag,
      :exit_flag,
      :entrance_type,
      :description,
      :position_input,
      :address,
      :zip_code,
      :city_name,
      :country,
      :created_at,
      :updated_at,
    )
  end
end