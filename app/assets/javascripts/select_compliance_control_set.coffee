$ ->
  select = document.getElementById('compliance_control_set')
  select.oninvalid = () ->
    key = if select.options.length == 0 then 'empty_list' else 'no_item_selected'
    select.setCustomValidity(I18n.t("referentials.select_compliance_control_set.select.#{key}"))