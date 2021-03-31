import { isEmpty } from 'lodash'

export default class RefreshForm {
  constructor(typeSelector, exportedLinesSelector, resourceName) {
    this.typeSelector = typeSelector
    this.exportedLinesSelector = exportedLinesSelector
    this.resourceName = resourceName
  }

  get isNew() {
    return window.location.pathname.includes('new')
  }

  get baseUrl() {
    return `${window.location.origin}/refresh_form/${this.resourceName}`
  }

  onTypeChange(callback) {
    $(this.typeSelector).on('change', e => {
      const { value: type } = e.target

      if (isEmpty(type)) return $("#type_slave").html('')

      $("#type_slave").load(`${this.baseUrl}/edit_type?type=${type}`, () => {
        callback()
      })
    })

    this.isNew && $(this.typeSelector).trigger('change')
  }

  onExportedLinesChange() {
    $(this.exportedLinesSelector).on('change', e => {
      const { value: exported_lines } = e.target

      if (isEmpty(exported_lines)) return $("#exported_lines_slave").html('')
    
      $("#exported_lines_slave").load(`${this.baseUrl}/edit_exported_lines?exported_lines=${exported_lines}&type=${$(this.typeSelector).val()}`, () => {
        $("[data-select2ed='true']").select2()
      })
    })

    this.isNew && $(this.exportedLinesSelector).trigger('change')
  }

  init() {
    if (this.isNew) {
      this.onTypeChange(() => this.onExportedLinesChange())
    } else {
      this.onTypeChange()
      this.onExportedLinesChange()
    }
  }
}