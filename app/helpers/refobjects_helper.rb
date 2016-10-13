module RefobjectsHelper

  def table_builder collection, columns, actions = [], cls = nil
    return unless collection.present?

    head = content_tag :thead do
      content_tag :tr do
        columns.each do |col|
          concat content_tag(:th, collection.first.respond_to?(col) ? col.to_s.titleize : "Doesn't exist")
        end
        concat content_tag :th, "Actions" if actions.any?
      end
    end

    body = content_tag :tbody do
      collection.collect { |item|
        content_tag :tr do
          columns.collect { |col|
            concat content_tag(:td, item.try(col))
          }.to_s.html_safe
          # Build links
          concat content_tag :td, autolinks_builder(item, actions, :xs) if actions.any?
        end
      }.join().html_safe
    end

    content_tag :table, head.concat(body), class: cls
  end

  def autolinks_builder(item, actions, cls)
    link = []

    actions.each do |action|
      if action == "show"
        showlink = link_to({controller: params[:controller], action: action, id: item.id}, class: 'btn btn-default') do
          content_tag :span, "", class: 'fa fa-eye'
        end
        link << showlink
      elsif action == "edit"
        editlink = link_to({controller: params[:controller], action: action, id: item.id}, class: 'btn btn-default') do
          content_tag :span, "", class: 'fa fa-pencil'
        end
        link << editlink
      elsif action == "delete"
        deletelink = link_to({controller: params[:controller], action: "show", id: item.id}, method: :delete, data: { confirm: 'Are you sure?'}, class: 'btn btn-default') do
          content_tag :span, "", class: 'fa fa-trash-o'
        end
        link << deletelink
      end
    end

    content_tag :div, class: "btn-group btn-group-#{cls}" do
      link.join().html_safe
    end
  end

end
