import { isEmpty } from 'lodash'
import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const $referentialId = $('#export_referential_id')
const $lineIds = $('#export_line_ids')
const referentialId = $referentialId.val()

// $lineIds.prop('disabled', isEmpty(referentialId)) // Disable select if referentialId is empty
// !isEmpty(referentialId) &&
//   $lineIds.data('ajaxPath', `/referentials/${referentialId}/autocomplete/lines`) // Set the path if referentialId is already set

// $referentialId.on('change', e => {
//   const { value: referentialId } = e.target

//   $lineIds.prop('disabled', isEmpty(referentialId))
//   $lineIds.empty()
//   $lineIds.data('ajaxPath', `/referentials/${referentialId}/autocomplete/lines`)
// })

// const options = {
//   minimumInputLength: 0,
//   placeholder: I18n.t('exports.form.line_name'),
//   allowClear: true,
//   multiple: true
// }

// new AjaxAutoComplete($lineIds, options).init()
