# coding: utf-8
module NewapplicationHelper

  # Replacement message
  def replacement_msg text
    content_tag :div, '', class: 'alert alert-warning' do
      icon = content_tag :span, '', class: 'fa fa-lg fa-info-circle', style: 'margin-right:7px;'
      icon + text
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

  def javascript_additional_packs *packs
    packs.each do |pack|
      additional_pack = content_for?(:additional_packs) ? " #{pack}" : pack

     content_for(:additional_packs, *additional_pack)
    end
  end
end
