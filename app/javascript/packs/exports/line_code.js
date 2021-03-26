import { isEmpty } from 'lodash'
import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

const $referentialId = $('#export_referential_id')
const $exportLineCode = $('#export_line_code')

// Disable #export_line_code if #export_referential_id is empty
$exportLineCode.prop('disabled',  isEmpty($referentialId.val())) 

$referentialId.on('change', e => {
  const { value: referentialId } = e.target

  $exportLineCode.prop('disabled',isEmpty(referentialId))
  $exportLineCode.empty()
  $exportLineCode.data('ajaxPath', `/referentials/${referentialId}/autocomplete/lines`)
})
  
new AjaxAutoComplete($exportLineCode).init()
