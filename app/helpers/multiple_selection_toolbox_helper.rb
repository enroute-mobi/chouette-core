module MultipleSelectionToolboxHelper
  # Box of links that floats at the bottom right of the page
  # c.f. https://projects.af83.io/issues/5206
  # #5206 method too long
  def multiple_selection_toolbox(actions, collection_name:)
    links = content_tag :ul do
      
      # #5206 `if params[:controller]` mieux passer comme parametre si besoin
      delete_path = nil

      if params[:controller] = 'workbenches'
        delete_path = referentials_workbench_path
      end

      actions.map do |action|
        if action == :delete
          action_link = link_to(
            '#',
            method: :delete,
            data: {
              path: delete_path,
              # #5206 Missing Translations
              confirm: t('actions.are_you_sure')
            },
            title: t("actions.#{action}")
          ) do
            content_tag :span, '', class: 'fa fa-trash'
          end
        end

        content_tag :li, action_link, class: 'st_action'
      end.join.html_safe
    end

    label = content_tag(
      :span,
      ("<span>0</span> #{t('table_builders.selected_elements')}").html_safe,
      class: 'info-msg'
    )

    content_tag :div, '', 
      class: 'select_toolbox noselect',
      id: "selected-#{collection_name}-action-box" do
      links + label
    end
  end
end
