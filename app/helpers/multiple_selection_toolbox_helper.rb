module MultipleSelectionToolboxHelper
  # Box of links that floats at the bottom right of the page
  def multiple_selection_toolbox(workbench_id, *actions, collection_name:)
    links = content_tag :ul do

      actions.flatten.map{ |action| make_action action, workbench_id }
        .join
        .html_safe
    end

    label = content_tag(
      :span,
      ("<span>0</span> #{t 'info.selected_elements'}").html_safe,
      class: 'info-msg'
    )

    content_tag :div, '', 
      class: 'select_toolbox noselect',
      id: "selected-#{collection_name}-action-box" do
        links + label
      end
  end


  private

  def make_action action, workbench_id
    if action == :delete
      action_link = link_to(
        '#',
        method: :delete,
        data: {
          path: referentials_workbench_path(workbench_id),
          confirm: 'Etes-vous sûr(e) de vouloir effectuer cette action ?'
        },
        title: t("actions.#{action}")
      ) do
        content_tag :span, '', class: 'fa fa-trash'
      end
    end

    content_tag :li, action_link, class: 'st_action'
  end
end
