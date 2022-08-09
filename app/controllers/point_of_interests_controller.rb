class PointOfInterestsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => PointOfInterest::Base

  before_action :decorate_point_of_interest, only: %i[show new edit]
  after_action :decorate_point_of_interest, only: %i[create update]

  before_action :point_of_interest_params, only: [:create, :update]

  belongs_to :workbench
  belongs_to :shape_referential, singleton: true

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @point_of_interests = PointOfInterestDecorator.decorate(
          collection,
          context: {
            workbench: @workbench,
          }
        )
      end
    end
  end

  protected

  alias point_of_interest resource
  alias shape_referential parent

  def collection
    @point_of_interests = parent.point_of_interests.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_point_of_interest
    object = point_of_interest rescue build_resource
    @point_of_interest = PointOfInterestDecorator.decorate(
      object,
      context: {
        workbench: @workbench
      }
    )
  end

  def point_of_interest_params
    params.require(:point_of_interest).permit(
      :name,
      :url,
      :position_input,
      :address_line_1,
      :zip_code,
      :city_name,
      :country,
      :email,
      :phone,
      :created_at,
      :updated_at,
      :point_of_interest_category_id,
      :shape_provider_id,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
      point_of_interest_hours_attributes: [:id, :opening_time_of_day, :closing_time_of_day, :week_days, :value, :_destroy],
    )
  end
end
