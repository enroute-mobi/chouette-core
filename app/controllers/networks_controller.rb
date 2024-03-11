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
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @networks = decorate_networks(@networks)
      }

      format.js {
        @networks = decorate_networks(@networks)
      }
    end
  end

  protected

  def collection
    @q = line_referential.networks.ransack(params[:q])

    if sort_column && sort_direction
      @networks ||= @q.result(:distinct => true).order(sort_column + ' ' + sort_direction).paginate(:page => params[:page])
    else
      @networks ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
    end
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

  def decorate_networks(networks)
    NetworkDecorator.decorate(
      networks,
      context: {
        workbench: workbench,
        line_referential: line_referential
      }
    )
  end
end
