module CustomViewHelper

  def render_custom_view(view)
    organisation = respond_to?(:current_organisation) ? current_organisation : nil
    view_name = [view, organisation.try(:custom_view)].compact.join('_')
    Rails.logger.debug "Render custom view #{view_name}"
    render partial: view_name
  end

end
