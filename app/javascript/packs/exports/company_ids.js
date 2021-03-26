import { isEmpty } from 'lodash'
import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const $referentialId = $('#export_referential_id')
const $companyIds = $('#export_company_ids')
const referentialId = $referentialId.val()

$companyIds.prop('disabled', isEmpty(referentialId)) // Disable select if referentialId is empty
!isEmpty(referentialId) &&
  $companyIds.data('ajaxPath', `/referentials/${referentialId}/autocomplete/companies`) // Set the path if referentialId is already set

$referentialId.on('change', e => {
  const { value: referentialId } = e.target

  $companyIds.prop('disabled', isEmpty(referentialId))
  $companyIds.empty()
  $companyIds.data('ajaxPath', `/referentials/${referentialId}/autocomplete/companies`)
})

const options = {
  minimumInputLength: 0,
  placeholder: I18n.t('exports.form.company_name'),
  allowClear: true,
  multiple: true
}

new AjaxAutoComplete($companyIds, options).init()