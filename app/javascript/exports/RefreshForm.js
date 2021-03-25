import { isEmpty } from 'lodash'

export default class RefreshForm {
  constructor(typeSelector, exportedLinesSelector, resourceName) {
    this.typeSelector = typeSelector
    this.exportedLinesSelector = exportedLinesSelector
    this.resourceName = resourceName
  }

  init() {
    $(this.typeSelector).on('change', e => {
      const { value: type } = e.target

      if (isEmpty(type)) return $("#type_slave").html('')

      const baseUrl = `${window.location.origin}/refresh_form/${this.resourceName}`

      $("#type_slave").load(`${baseUrl}/edit_type?type=${type}`, () => {
        $(this.exportedLinesSelector).on('change', e => {
          const { value: exported_lines } = e.target

          if (isEmpty(exported_lines)) return $("#exported_lines_slave").html('')
        
          $("#exported_lines_slave").load(`${baseUrl}/edit_exported_lines?exported_lines=${exported_lines}&type=${$(this.typeSelector).val()}`, () => {
            $("[data-select2ed='true']").select2()
          })
        })
        $(this.exportedLinesSelector).trgger('change')
      })
    })
    $(this.typeSelector).trigger('change')
  }
}