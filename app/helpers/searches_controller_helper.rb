# frozen_string_literal: true

module SearchesControllerHelper
  def saved_search_path(saved_search)
    workbench_stop_area_referential_search_path saved_search.workbench, saved_search, parent_resources: :stop_areas
  end

  def workbench_stop_areas_searches_path(workbench)
    workbench_stop_area_referential_searches_path workbench, parent_resources: :stop_areas
  end

  def workbench_stop_areas_search_path(workbench, search)
    workbench_stop_area_referential_search_path workbench, search.id, parent_resources: :stop_areas
  end
end
