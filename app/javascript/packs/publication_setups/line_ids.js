import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const workgroupId = window.location.pathname.match(/\d+/)[0]
const $lineIds = $('#export_line_ids')
$lineIds.data('ajaxPath', `/workgroups/${workgroupId}/autocomplete/lines`)

const options = {
  minimumInputLength: 0,
  placeholder: I18n.t('exports.form.line_name'),
  allowClear: true,
  multiple: true
}

new AjaxAutoComplete($lineIds, options).init()