# frozen_string_literal: true

class NetworksController < Chouette::LineReferentialController
  include ApplicationHelper

  defaults :resource_class => Chouette::Network

  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  def show
    show! do
      @network = @network.decorate(
        context: {
          workbench: workbench,
          line_referential: line_referential
        }
      )
    end
  end

  def index
    index! do |format|
      format.html {
        @networks = NetworkDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
            line_referential: line_referential
          }
        )
      }
    end
  end

  protected

  def scope
    parent.networks
  end

  def search
    @search ||= Search::Network.from_params(params, line_referential: line_referential)
  end

  def collection
    @collection ||= search.search scope
  end

  def network_params
    @network_params ||= params.require(:network).permit(
      :objectid,
      :object_version,
      :version_date,
      :description,
      :name,
      :registration_number,
      :source_name,
      :source_type_name,
      :source_identifier,
      :comment,
      :line_provider_id
    )
  end

  private

  def sort_column
    line_referential.networks.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end
end
