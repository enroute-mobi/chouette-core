import Alpine from 'alpinejs'

Alpine.data('localesForm', ({ firstIndex = 0 } = {}) => ({
  addedLocales: [],
  nextIndex: firstIndex,

  addLocale() {
    const select = this.$refs.addLocale
    const tomSelect = select.tomselect
    const code = tomSelect ? tomSelect.getValue() : select.value
    if (!code) return

    const name = tomSelect ? tomSelect.options[code].text : select.selectedOptions[0].text
    const alpha2 = JSON.parse(select.dataset.countryCodes || '{}')[code]

    this.addedLocales.push({ index: this.nextIndex++, code, name, alpha2 })

    if (tomSelect) {
      tomSelect.clear()
      tomSelect.removeOption(code, true)
    } else {
      select.selectedOptions[0].remove()
    }
  },

  flagClass(alpha2) {
    return alpha2 ? `flag-icon flag-icon-${alpha2.toLowerCase()} mr-xs` : ''
  }
}))
