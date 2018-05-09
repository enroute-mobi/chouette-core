require 'table_builder_helper/column'
require 'table_builder_helper/custom_links'
require 'table_builder_helper/url'

# table_builder_2
# A Rails helper that constructs an HTML table from a collection of objects. It
# receives the collection and an array of columns that get transformed into
# `<td>`s. A column of checkboxes can be added to the left side of the table
# for multiple selection. Columns are sortable by default, but sorting can be
# disabled either at the table level or at the column level. An optional
# `links` argument takes a set of symbols corresponding to controller actions
# that should be inserted in a gear menu next to each row in the table. That
# menu will also be populated with links defined in `collection#action_links`,
# a list of `Link` objects defined in a decorator for the given object.
#
# Depends on `params` and `current_referential`.
#
# Example:
#   table_builder_2(
#     @companies,
#     [
#       TableBuilderHelper::Column.new(
#         name: 'ID Codif',
#         attribute: Proc.new { |n| n.try(:objectid).try(:local_id) },
#         sortable: false
#       ),
#       TableBuilderHelper::Column.new(
#         key: :name,
#         attribute: 'name',
#         link_to: lambda do |company|
#           referential_company_path(@referential, company)
#         end
#       ),
#       TableBuilderHelper::Column.new(
#         key: :phone,
#         attribute: 'phone'
#       ),
#       TableBuilderHelper::Column.new(
#         key: :email,
#         attribute: 'email'
#       ),
#       TableBuilderHelper::Column.new(
#         key: :url,
#         attribute: 'url'
#       ),
#     ],
#     links: [:show, :edit],
#     cls: 'table has-search',
#     overhead: [
#       {
#         title: 'one',
#         width: 1,
#         cls: 'toto'
#       },
#       {
#         title: 'two <span class="test">Info</span>',
#         width: 2,
#         cls: 'default'
#       }
#     ]
#   )
module TableBuilderHelper
  # TODO: rename this after migration from `table_builder`
  def table_builder_2(
    # An `ActiveRecord::Relation`, wrapped in a decorator to provide a list of
    # `Link` objects via an `#action_links` method
    collection,

    # An array of `TableBuilderHelper::Column`s
    columns,

    # When false, no columns will be sortable
    sortable: true,

    # When true, adds a column of checkboxes to the left side of the table
    selectable: false,

    # A set of controller actions that will be added as links to the top of the
    # gear menu
    links: [],

    # A CSS class to apply to the <table>
    cls: '',

    # A set of content, over the th line...
    overhead: [],

    # Possibility to override the result of collection.model
    model: nil,

    #overrides the params[:action] value
    action: nil

  )
    content_tag :table,
      thead(collection, columns, sortable, selectable, links.any?, overhead, model || collection.model, action || params[:action]) +
        tbody(collection, columns, selectable, links, overhead, model, action || params[:action]),
      class: cls
  end

  def self.item_row_class_name collection, model=nil
    model_name = model&.name

    model_name ||=
      if collection.respond_to?(:model)
        collection.model.name
      elsif collection.respond_to?(:first)
        collection.first.class.name
      else
        "item"
      end

    model_name.split("::").last.parameterize
  end

  private

  def thead(collection, columns, sortable, selectable, has_links, overhead, model, action)
    content_tag :thead do
      # Inserts overhead content if any specified
      over_head = ''

      unless overhead.empty?
        over_head = content_tag :tr, class: 'overhead' do
          oh_cont = []

          overhead.each do |h|
            oh_cont << content_tag(:th, raw(h[:title]), colspan: h[:width], class: h[:cls])
          end
          oh_cont.join.html_safe
        end
      end

      main_head = content_tag :tr do
        hcont = []

        if selectable
          hcont << content_tag(:th, checkbox(id_name: '0', value: 'all'))
        end

        columns.each do |column|
          if overhead.empty?
            hcont << content_tag(:th, build_column_header(
              column,
              sortable,
              model,
              params,
              params[:sort],
              params[:direction]
            ))

          else
            i = columns.index(column)

            if overhead[i].blank?
              if (i > 0) && overhead[i - 1][:width] && (overhead[i - 1][:width] > 1)
                clsArrayH = overhead[i - 1][:cls].split

                hcont << content_tag(:th, build_column_header(
                  column,
                  sortable,
                  model,
                  params,
                  params[:sort],
                  params[:direction]
                ), class: td_cls(clsArrayH))

              else
                hcont << content_tag(:th, build_column_header(
                  column,
                  sortable,
                  model,
                  params,
                  params[:sort],
                  params[:direction]
                ))
              end

            else
              clsArrayH = overhead[i][:cls].split

              hcont << content_tag(:th, build_column_header(
                column,
                sortable,
                model,
                params,
                params[:sort],
                params[:direction]
              ), class: td_cls(clsArrayH))

            end

          end
        end

        # Inserts a blank column for the gear menu
        last_item = collection.last
        action_links = last_item && last_item.respond_to?(:action_links) && (last_item&.action_links&.is_a?(AF83::Decorator::ActionLinks) ? last_item.action_links(action) : last_item.action_links)
        if has_links || action_links.try(:any?)
          hcont << content_tag(:th, '')
        end

        hcont.join.html_safe
      end

      (over_head + main_head).html_safe
    end
  end

  def tr item, columns, selectable, links, overhead, model_name, action
    klass = "#{model_name} #{model_name}-#{item.id}"
    content_tag :tr, class: klass do
      bcont = []
      if selectable
        disabled = selectable.respond_to?(:call) && !selectable.call(item)
        bcont << content_tag(
          :td,
          checkbox(id_name: item.try(:id), value: item.try(:id), disabled: disabled)
        )
      end

      columns.each do |column|
        value = column.value(item)
        extra_class = column.td_class(item)

        if column.linkable?
          path = column.link_to(item)
          link = value.present? && path.present? ? link_to(value, path) : value

          if overhead.empty?
            bcont << content_tag(:td, link, title: 'Voir', class: extra_class)

          else
            i = columns.index(column)

            if overhead[i].blank?
              if (i > 0) && overhead[i - 1][:width] && (overhead[i - 1][:width] > 1)
                clsArrayAlt = overhead[i - 1][:cls].split

                bcont << content_tag(:td, link, title: 'Voir', class: td_cls(clsArrayAlt, extra_class))

              else
                bcont << content_tag(:td, link, title: 'Voir', class: extra_class)
              end

            else
              clsArray = overhead[columns.index(column)][:cls].split

              bcont << content_tag(:td, link, title: 'Voir', class: td_cls(clsArray, extra_class))
            end
          end

        else
          if overhead.empty?
            bcont << content_tag(:td, value, class: extra_class)

          else
            i = columns.index(column)

            if overhead[i].blank?
              if (i > 0) && (overhead[i - 1][:width] > 1)
                clsArrayAlt = overhead[i - 1][:cls].split

                bcont << content_tag(:td, value, class: td_cls(clsArrayAlt, extra_class))

              else
                bcont << content_tag(:td, value, class: extra_class)
              end

            else
              clsArray = overhead[i][:cls].split

              bcont << content_tag(:td, value, class: td_cls(clsArray))
            end
          end
        end
      end

      action_links = item && item.respond_to?(:action_links) && (item.action_links.is_a?(AF83::Decorator::ActionLinks) ? item.action_links(action) : item.action_links)

      if links.any? || action_links.try(:any?)
        bcont << content_tag(
          :td,
          build_links(item, links, action),
          class: 'actions'
        )
      end

      bcont.join.html_safe
    end
  end

  def tbody(collection, columns, selectable, links, overhead, model = nil, action)
    model_name = TableBuilderHelper.item_row_class_name collection, model

    content_tag :tbody do
      collection.map do |item|
        tr item, columns, selectable, links, overhead, model_name, action
      end.join.html_safe
    end
  end

  def td_cls(a, extra_class="")
    out = [extra_class]
    if a.include? 'full-border'
      a.slice!(a.index('full-border'))

      out += a
    end
    out = out.select(&:present?).join(' ')
    out.present? ? out : nil
  end

  def build_links(item, links, action)
    trigger = content_tag(
      :div,
      class: 'btn dropdown-toggle',
      data: { toggle: 'dropdown' }
    ) do
      content_tag :span, '', class: 'fa fa-cog'
    end

    action_links = item.action_links
    if action_links.is_a?(AF83::Decorator::ActionLinks)
      menu = content_tag :div, class: 'dropdown-menu' do
        item.action_links(action).grouped_by(:primary, :secondary, :footer).map do |group, _links|
          if _links.any?
            content_tag :ul, class: group do
              _links.map{|link| gear_menu_link(link)}.join.html_safe
            end
          end
        end.join.html_safe
      end
    else
      menu = content_tag :ul, class: 'dropdown-menu' do
        (
          CustomLinks.new(item, pundit_user, links, referential, workgroup).links +
          action_links.select { |link| link.is_a?(Link) }
        ).map do |link|
          gear_menu_link(link)
        end.join.html_safe
      end
    end

    content_tag :div, trigger + menu, class: 'btn-group'
  end

  def build_column_header(
    column,
    table_is_sortable,
    model,
    params,
    sort_on,
    sort_direction
  )

    if !table_is_sortable || !column.sortable
      return column.header_label(model)
    end

    direction =
      if column.key.to_s == sort_on && sort_direction == 'desc'
        'asc'
      else
        'desc'
      end

    link_to(params.merge({direction: direction, sort: column.key})) do
      arrow_up = content_tag(
        :span,
        '',
        class: "fa fa-sort-asc #{direction == 'desc' ? 'active' : ''}"
      )
      arrow_down = content_tag(
        :span,
        '',
        class: "fa fa-sort-desc #{direction == 'asc' ? 'active' : ''}"
      )

      arrow_icons = content_tag :span, arrow_up + arrow_down, class: 'orderers'

      (
        column.header_label(model) +
        arrow_icons
      ).html_safe
    end
  end

  def checkbox(id_name:, value:, disabled: false)
    content_tag :div, '', class: 'checkbox' do
      check_box_tag(id_name, value, nil, disabled: disabled).concat(
        content_tag(:label, '', for: id_name)
      )
    end
  end

  def gear_menu_link(link)
    klass = []
    klass << link.extra_class if link.extra_class
    klass << 'delete-action' if link.method == :delete
    klass << 'disabled' if link.disabled
    content_tag(
      :li,
      link_to(
        link.disabled ? '#' : link.href,
        method: link.disabled ? nil : link.method,
        data: link.data,
        disabled: link.disabled
      ) do
        link.content
      end,
      class: (klass.join(' ') if klass.present?)
    )
  end

  def referential
    # Certain controllers don't define a `#current_referential`. In these
    # cases, avoid a `NoMethodError`.
    @__referential__ ||= try(:current_referential)
  end

  def workgroup
    # Certain controllers don't define a `#current_referential`. In these
    # cases, avoid a `NoMethodError`.
    @__workgroup__ ||= try(:current_workgroup)
  end
end
