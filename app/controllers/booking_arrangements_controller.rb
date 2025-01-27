# frozen_string_literal: true

class BookingArrangementsController < Chouette::LineReferentialController
  defaults resource_class: BookingArrangement

  def index
    index! do |format|
      format.html do
        @booking_arrangements = BookingArrangementDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end


  protected

  alias booking_arrangement resource


  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
      )
    end

  def scope
    @scope ||= parent.booking_arrangements
  end

  def search
    @search ||= Search::BookingArrangement.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def booking_arrangement_params
    @booking_arrangement_params ||= params.require(:booking_arrangement).permit(
      :line_provider_id,
      :name,
      :phone,
      :url,
      :booking_access,
      :minimum_booking_period,
      :book_when,
      :latest_booking_time,
      :buy_when,
      :booking_url,
      :booking_notes,
      booking_methods: [],
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end

end
