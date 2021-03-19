import '../../helpers/polyfills'

import { isEmpty } from 'lodash'

$("#export_referential_id").select2()

$('#export_type').on('change', e => {
  const { value: type } = e.target

  if (isEmpty(type)) return $("#type_slave").html('')

  const baseUrl = window.location.href.split('/new')[0]

  $("#type_slave").load(`${baseUrl}/refresh_form?type=${type}`, () => {
    $('#exported_lines').on('change', e => {
      const { value: exported_lines } = e.target

      if (isEmpty(exported_lines)) return $("#exported_lines_slave").html('')
    
      $("#exported_lines_slave").load(`${baseUrl}/refresh_form?exported_lines=${exported_lines}`, () => {
        $("[data-select2ed='true']").select2()
      });
    })
  });
})
