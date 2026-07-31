import TomSelect from 'tom-select'

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll('select.autocomplete_select').forEach((el) => {
    // test if el is a multiple select input
    let plugin_list = []
    if (el.hasAttribute("multiple")) {
      plugin_list = ['clear_button', 'remove_button']
    }
    else {
      plugin_list = ['clear_button']
    }

    let settings = {
      plugins: plugin_list,
      openOnFocus: true,
      sortField: [{field:'$order'},{field:'$score'}]
    }

    if (Array.prototype.some.call(el.options, o => o.value === "" && o.text != "")) {
      settings.allowEmptyOption = true
    }

    // country selects prefix each entry with its flag. The alpha2 code cannot be
    // derived from the option value (en_UK -> GB), so it comes from a lookup map.
    if (el.classList.contains('country-select')) {
      const countryCodes = JSON.parse(el.dataset.countryCodes || '{}')
      const withFlag = (data, escape) => {
        const alpha2 = countryCodes[data.value]
        const flag = alpha2 ? `<span class="flag-icon flag-icon-${alpha2.toLowerCase()} mr-xs"></span>` : ''
        return `<div>${flag}${escape(data.text)}</div>`
      }
      settings.render = { option: withFlag, item: withFlag }
    }

    new TomSelect(el, settings)
  })
})

