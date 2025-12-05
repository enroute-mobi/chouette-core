# frozen_string_literal: true

class WorkgroupOutputsController < Chouette::WorkgroupController
  respond_to :html, only: [:show]
  defaults resource_class: Workgroup

  def show
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search(Search::WorkgroupAggregate.attributes_from_params(params))
    end

    show! do |format|
      format.html do
        collection # to mimic inherited resources index and preload search
        @chart = @search.chart(scope) if @search && @search.graphical?

        unless @chart
          @aggregates = AggregateDecorator.decorate(collection)
        end
      end
    end
  end

  def saved_searches
    @saved_searches ||= workgroup.saved_searches.for(::Search::WorkgroupAggregate)
  end

  protected

  alias resource workgroup

  def scope
    @scope ||= workgroup.aggregates
  end

  def search
    @search ||= Search::WorkgroupAggregate.from_params(params, workgroup: workgroup)
  end

  def collection
    @collection ||= search.search(scope)
  end
end
