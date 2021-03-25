import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const workgroupId = window.location.pathname.match(/\d+/)[0]
const $lineProviderIds = $('#export_line_provider_ids')
$lineProviderIds.data('ajaxPath', `/workgroups/${workgroupId}/autocomplete/line_providers`)

const options = {
  minimumInputLength: 0,
  placeholder: I18n.t('exports.form.line_provider_name'),
  allowClear: true,
  multiple: true
}

new AjaxAutoComplete($lineProviderIds, options).init()