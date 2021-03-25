import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const workgroupId = window.location.pathname.match(/\d+/)[0]
const $companyIds = $('#export_company_ids')
$companyIds.data('ajaxPath', `/workgroups/${workgroupId}/autocomplete/companies`)

const options = {
  minimumInputLength: 0,
  placeholder: I18n.t('exports.form.company_name'),
  allowClear: true,
  multiple: true
}

new AjaxAutoComplete($companyIds, options).init()