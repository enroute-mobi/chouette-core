module SearchHelper

  # Provides a simpler path helper for Stop Areas saved searches
  # TODO: See if it's usefull with other resources
  def workbench_stop_areas_search_path(workbench, saved_search)
    workbench_stop_area_referential_search_path workbench, saved_search.id, parent_resources: :stop_areas
  end

  def saved_search_path(saved_search)
    parent_resources = saved_search.search_type.demodulize.underscore.pluralize.to_sym

    path_method = "workbench_#{parent_resources}_search_path"
    send path_method, saved_search.workbench, saved_search # , parent_resources: :stop_areas
  end

  def filter_item_class q, key
    ActiveSupport::Deprecation.warn "#filter_item_class should be replaced by smart Search inputs"

    active = false
    if q.present? && q[key].present?
      val = q[key]
      if val.is_a?(Array)
        active = val.any? &:present?
      elsif val.respond_to?(:values)
        active = val.values.any? {|v| v.present? && v != "false" && v != "0" }
      else
        active = true
      end
    end
    active ? 'active' : 'inactive'
  end

end
