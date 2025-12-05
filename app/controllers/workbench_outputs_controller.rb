# frozen_string_literal: true

class WorkbenchOutputsController < Chouette::WorkbenchController
  respond_to :html, only: [:show]
  defaults resource_class: Workbench

  def show
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search(Search::Merge.attributes_from_params(params))
    end

    show! do |format|
      format.html do
        @workbench_merges = MergeDecorator.decorate(collection, context: { workbench: workbench })
      end
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::Merge)
  end

  protected

  alias resource workbench

  def scope
    @scope ||= workbench.merges
  end

  def search
    @search ||= Search::Merge.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search(scope)
  end
end
