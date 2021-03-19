import { isEmpty } from 'lodash'
import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const workbenchId = window.location.pathname.match(/(\d+)/)[0]
const $referentialId = $('#export_referential_id')
const $lineProviderIds = $('#export_line_provider_ids')
const referentialId = $referentialId.val()

$lineProviderIds.prop('disabled', isEmpty(referentialId))  // Disable select if referentialId is empty
!isEmpty(referentialId) &&
  $lineProviderIds.data('ajaxPath', `/workbenches/${workbenchId}/autocomplete/line_providers`) // Set the path if referentialId is already set

$referentialId.on('change', e => {
  const { value: referentialId } = e.target

  $lineProviderIds.prop('disabled', isEmpty(referentialId))
  $lineProviderIds.empty()
  $lineProviderIds.data('ajaxPath', `/workbenches/${workbenchId}/autocomplete/line_providers`)
})

const options = {
  minimumInputLength: 0,
  placeholder: I18n.t('exports.form.line_provider_name'),
  allowClear: true,
  multiple: true
}

new AjaxAutoComplete($lineProviderIds, options).init()