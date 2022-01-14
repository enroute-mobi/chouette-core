# coding: utf-8
module NewapplicationHelper

  # Table Builder
  def table_builder collection, columns, actions, selectable = [], cls = nil
    return unless collection.present?

    head = content_tag :thead do
      content_tag :tr do
        hcont = []

        unless selectable.empty?
          cbx = content_tag :div, '', class: 'checkbox' do
            check_box_tag('0', 'all').concat(content_tag(:label, '', for: '0'))
          end
          hcont << content_tag(:th, cbx)
        end

        columns.map do |k, v|
          if ["ID Codifligne", "Oid", "OiD", "ID", "ID Reflex", "Arrêt de départ", "Arrêt d'arrivée", "Période de validité englobante", "Période englobante", "Nombre de courses associées", "Journées d'application", "Arrêts de l'itinéraire", "Arrêts inclus dans l'ITL"].include? k
            hcont << content_tag(:th, k)
          else
            hcont << content_tag(:th, sortable_columns(collection, k))
          end
        end
        hcont << content_tag(:th, '') if actions.any?

        hcont.join.html_safe
      end
    end

    body = content_tag :tbody do
      collection.collect do |item|

        content_tag :tr do
          bcont = []

          unless selectable.empty?
            cbx = content_tag :div, '', class: 'checkbox' do
              check_box_tag(item.try(:id), item.try(:id)).concat(content_tag(:label, '', for: item.try(:id)))
            end
            bcont << content_tag(:td, cbx)
          end

          columns.map do |k, attribute|
            value =
              if Proc === attribute
                attribute.call(item)
              else
                item.try(attribute)
              end
            if attribute == 'name' or attribute == 'comment'
              lnk = []

              unless item.class == Calendar or item.class == Referential
                if current_referential
                  lnk << current_referential
                  lnk << item.line if item.respond_to? :line
                  lnk << item.route.line if item.class == Chouette::RoutingConstraintZone
                  lnk << item if item.respond_to? :line_referential
                  lnk << item.stop_area if item.respond_to? :stop_area
                  lnk << item if item.respond_to? :stop_points or item.class.to_s == 'Chouette::TimeTable'
                elsif item.respond_to? :referential
                  lnk << item.referential
                end
              else
                lnk << item
              end

              bcont << content_tag(:td, link_to(value, lnk), title: 'Voir')
            else
              bcont << content_tag(:td, value)
            end
          end
          bcont << content_tag(:td, links_builder(item, actions), class: 'actions') if actions.any?

          bcont.join.html_safe
        end
      end.join.html_safe
    end

    if selectable.empty?
      content_tag :table, head + body, class: cls
    else
      content_tag :div, '', class: 'select_table' do
        table = content_tag :table, head + body, class: cls
        toolbox = select_toolbox(selectable)
        table + toolbox
      end
    end
  end

  def links_builder(item, actions)
    trigger = content_tag :div, class: 'btn dropdown-toggle', data: { toggle: 'dropdown' } do
      content_tag :span, '', class: 'fa fa-cog'
    end

    menu = content_tag :ul, class: 'dropdown-menu' do
      actions.collect do |action|
        polymorph_url = []

        unless [:show, :delete].include? action
          polymorph_url << action
        end

        unless item.class == Calendar or item.class == Referential
          if current_referential
            polymorph_url << current_referential
            polymorph_url << item.line if item.respond_to? :line
            polymorph_url << item.route.line if item.class == Chouette::RoutingConstraintZone
            polymorph_url << item if item.respond_to? :line_referential
            polymorph_url << item.stop_area if item.respond_to? :stop_area
            polymorph_url << item if item.respond_to? :stop_points or item.class.to_s == 'Chouette::TimeTable'
          elsif item.respond_to? :referential
            polymorph_url << item.referential
          end
        else
          polymorph_url << item
        end

        if action == :delete
          if policy(item).present?
            if policy(item).destroy?
              content_tag :li, '', class: 'delete-action' do
                link_to(polymorph_url, method: :delete, data: { confirm: I18n.t('are_you_sure') }) do
                  txt = t("actions.#{action}")
                  pic = content_tag :span, '', class: 'fa fa-trash'
                  pic + txt
                end
              end
            end
          else
            content_tag :li, '', class: 'delete-action' do
              link_to(polymorph_url, method: :delete, data: { confirm: I18n.t('are_you_sure') }) do
                txt = t("actions.#{action}")
                pic = content_tag :span, '', class: 'fa fa-trash'
                pic + txt
              end
            end
          end

        elsif action == :edit
          if policy(item).present?
            if policy(item).update?
              content_tag :li, link_to(t("actions.#{action}"), polymorph_url)
            end
          else
            content_tag :li, link_to(t("actions.#{action}"), polymorph_url)
          end
        elsif action == :archive
          unless item.referential_read_only?
            content_tag :li, link_to(t("actions.#{action}"), polymorph_url, method: :put)
          end
        elsif action == :unarchive
          if item.archived?
            content_tag :li, link_to(t("actions.#{action}"), polymorph_url, method: :put)
          end
        else
          permission = "#{action}?"
          if !policy(item).respond_to?(permission) || policy(item).public_send(permission)
            content_tag :li, link_to(t("actions.#{action}"), polymorph_url)
          end
        end
      end.join.html_safe
    end

    content_tag :div, trigger + menu, class: 'btn-group'

  end

  def sortable_columns collection, key
    direction = (key.to_s == params[:sort] && params[:direction] == 'desc') ? 'asc' : 'desc'

    link_to(params.merge({direction: direction, sort: key})) do
      pic1 = content_tag :span, '', class: "fa fa-sort-up #{(direction == 'desc') ? 'active' : ''}"
      pic2 = content_tag :span, '', class: "fa fa-sort-down #{(direction == 'asc') ? 'active' : ''}"

      pics = content_tag :span, pic1 + pic2, class: 'orderers'
      obj = collection.model.to_s.gsub('Chouette::', '').scan(/[A-Z][a-z]+/).join('_').downcase

      (I18n.t("activerecord.attributes.#{obj}.#{key}") + pics).html_safe
    end
  end

  # Actions on select toolbox (for selectables tables)
  def select_toolbox(actions)
    tools = content_tag :ul do
      dPath = nil
      dPath = referentials_workbench_path if params[:controller] = 'workbenches'

      actions.collect do |action|
        if action == :edit
          actitem = link_to('#', title: t("actions.#{action}")) do
            content_tag :span, '', class: 'fa fa-pencil-alt'
          end
        elsif action == :delete
          actitem = link_to('#', method: :delete, data: { path: dPath, confirm: I18n.t('are_you_sure') }, title: t("actions.#{action}")) do
            content_tag :span, '', class: 'fa fa-trash'
          end
        end

        content_tag :li, actitem, class: 'st_action'
      end.join.html_safe

    end
    content_tag :div, '', class: 'select_toolbox noselect' do
      tools.concat(content_tag(:span, ("<span>0</span> élément(s) sélectionné(s)").html_safe, class: 'info-msg'))
    end
  end

  # Replacement message
  def replacement_msg text
    content_tag :div, '', class: 'alert alert-warning' do
      icon = content_tag :span, '', class: 'fa fa-lg fa-info-circle', style: 'margin-right:7px;'
      icon + text
    end
  end

  # PageHeader builder
  def pageheader pageicon, pagetitle, desc = nil, meta = nil, mainaction = nil, &block

    firstRow = content_tag :div, '', class: 'row' do
      # Left part with pageicon & pagetitle & desc
      left = content_tag :div, '', class: 'col-lg-9 col-md-8 col-sm-7 col-xs-7' do
        picon = content_tag :div, '', class: 'page-icon' do
          content_tag :span, '', class: "sb sb-#{pageicon}"
        end
        ptitle = content_tag :div, '', class: 'page-title' do
          content_tag :h1, pagetitle, title: desc
        end

        picon + ptitle
      end
      # Right part with meta & mainaction
      right = content_tag :div, '', class: 'col-lg-3 col-md-4 col-sm-5 col-xs-5 text-right' do
        content_tag :div, '', class: 'page-action' do
          a = content_tag :div, meta.try(:html_safe), class: 'small'
          b = mainaction.try(:html_safe)

          a + b
        end
      end

      left + right
    end

    content_tag :div, '', class: 'page_header' do
      content_tag :div, '', class: 'container-fluid' do
        if block_given?
          firstRow + capture(&block)
        else
          firstRow
        end
      end
    end
  end

  # Definition list
  def definition_list title, test, options={}
    return unless test.present?

    togglable = options[:togglable]
    togglable = 0 if togglable.present? && !togglable.is_a?(Fixnum)

    extr_class = togglable ? 'togglable' : ''
    head = content_tag(:div, title, class: "dl-head #{extr_class}")

    body = content_tag :div, class: 'dl-body' do
      cont = []
      i = 0
      test.map do |k, v|
        extr_class = togglable && i >= togglable ? 'togglable' : ''
        cont << content_tag(:div, k, class: "dl-term #{extr_class}")
        cont << content_tag(:div, v, class: "dl-def #{extr_class}")
        i += 1
      end
      cont.join.html_safe
    end

    content_tag :div, '', class: 'definition-list' do
      head + body
    end
  end

  # ModalBox Builder
  def modalbox id, &block
    content_tag(:div, '', class: 'modal fade', id: id, tabindex: 1, role: 'dialog') do
      content_tag(:div, '', class: 'modal-container') do
        content_tag(:div, '', class: 'modal-dialog') do
          content_tag(:div, '', class: 'modal-content') do
            yield
          end
        end
      end
    end
  end

  def javascript_additional_packs *packs
    packs.each do |pack|
      additional_pack = content_for?(:additional_packs) ? " #{pack}" : pack

     content_for(:additional_packs, *additional_pack)
    end
  end
end
