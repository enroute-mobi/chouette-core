# frozen_string_literal: true

class ReferentialLinesController < Chouette::ReferentialController
  defaults :resource_class => Chouette::Line, :collection_name => 'lines', :instance_name => 'line'
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :geojson, :only => :show
  respond_to :js, :only => :index

  def show
    show! do |format|
      @routes = RouteDecorator.decorate(
        searched_routes,
        context: {
          referential: referential,
          workbench: current_workbench,
          line: @line
        }
      )

      @line = ReferentialLineDecorator.decorate(
        @line,
        context: {
          referential: referential,
          workbench: current_workbench,
          current_organisation: current_organisation
        }
      )
    end
  end

  protected

  def scope
    @line.routes
  end

  def search
    @search ||= Search::Route.from_params(params, workbench: current_workbench)
  end

  def searched_routes
    @searched_routes ||= search.search scope
  end
end
