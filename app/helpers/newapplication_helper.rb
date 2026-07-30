# coding: utf-8
module NewapplicationHelper

  # Replacement message
  def replacement_msg text
    content_tag :div, '', class: 'alert alert-warning' do
      icon = content_tag :span, '', class: 'fa fa-lg fa-info-circle', style: 'margin-right:7px;'
      icon + text
    end
  end

  def javascript_additional_packs *packs
    packs.each do |pack|
      additional_pack = content_for?(:additional_packs) ? " #{pack}" : pack

     content_for(:additional_packs, *additional_pack)
    end
  end
end
