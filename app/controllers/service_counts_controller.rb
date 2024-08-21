# frozen_string_literal: true

class ServiceCountsController < Chouette::ReferentialController
  defaults resource_class: ServiceCount

  respond_to :html

  def index # rubocop:disable Metrics/MethodLength
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    index! do |format|
      format.html do
        @chart = @search.chart(scope) if @search.graphical?
      end
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::ServiceCount)
  end

  protected

  def scope
    parent.service_counts
  end

  def search
    @search ||= ::Search::ServiceCount.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search(scope)
  end
end
