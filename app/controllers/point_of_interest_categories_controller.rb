# frozen_string_literal: true

class PointOfInterestCategoriesController < Chouette::TopologicReferentialController
  include ApplicationHelper

  defaults :resource_class => PointOfInterest::Category

  before_action :decorate_point_of_interest_category, only: %i[show new edit]
  after_action :decorate_point_of_interest_category, only: %i[create update]

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @point_of_interest_categories = PointOfInterestCategoryDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias point_of_interest_category resource

  def collection
    @point_of_interest_categories = parent.point_of_interest_categories.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_point_of_interest_category
    object = point_of_interest_category rescue build_resource
    @point_of_interest_category = PointOfInterestCategoryDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def point_of_interest_category_params
    @point_of_interest_category_params ||= params.require(:point_of_interest_category).permit(
      :name,
      :created_at,
      :updated_at,
      :parent_id,
      :shape_provider_id,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
