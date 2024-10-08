# frozen_string_literal: true

class EntrancesController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  defaults :resource_class => Entrance

  before_action :entrance_params, only: [:create, :update]

  respond_to :html, :xml, :json, :geojson

  def index
    index! do |format|
      format.html do
        @entrances = EntranceDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  def show
    show! do |format|
      @entrance = @entrance.decorate context: { workbench: workbench }

      format.geojson { render 'entrances/show.geo' }
    end
  end

  def update
    update! do
      if entrance_params[:entrance_ids]
        workbench_stop_area_referential_entrances_path workbench, @entrance
      else
        workbench_stop_area_referential_entrance_path workbench, @entrance
      end
    end
  end

  protected

  alias_method :entrance, :resource

  def scope
    stop_area_referential.entrances
  end

  def search
    @search ||= Search::Entrance.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def entrance_params
    @entrance_params ||= params.require(:entrance).permit(
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
      :address_line_1,
      :zip_code,
      :city_name,
      :country,
      :created_at,
      :updated_at,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
