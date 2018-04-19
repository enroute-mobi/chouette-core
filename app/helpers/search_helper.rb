module SearchHelper

  def link_with_search(name, search, html_options = {})
    is_current = (@q and search.all? { |k,v| @q.send(k) == v })
    if is_current
      html_options[:class] = [html_options[:class], "current"].compact.join(" ")
    end
    link_to name, params.deep_merge("q" => search,:page => 1), html_options
  end

  def filter_item_class q, key
    active = false
    if q.present? && q[key].present?
      val = q[key]
      if val.is_a?(Array)
        active = val.any? &:present?
      elsif val.is_a?(Hash)
        active = val.values.any? {|v| v.present? && v != "false" && v != "0" }
      else
        active = true
      end
    end
    active ? 'active' : 'inactive'
  end

end
