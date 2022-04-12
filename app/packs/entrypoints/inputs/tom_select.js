import TomSelect from 'tom-select'
class ConfigBuilder {
  static call(select, config) {
    const { type, url, ...payload } = config
    
    let specificConfig

    switch(type) {
      case 'ajax':
        specificConfig = ConfigBuilder.configs.ajax(select, url)
        break
      case 'create':
        specificConfig = ConfigBuilder.configs.create
        break
      default:
        specificConfig = {}
    }

    return {
      ...ConfigBuilder.configs.default,
      ...payload,
      ...specificConfig
    }
  }

  static get configs() {
    return {
      default: {
        valueField: 'id',
        labelField: 'text',
        plugins: ['clear_button'],
        render: {
          item: (data, escape) => (
            `<div data-group="${data.group}">${escape(data.text)}</div>`
          ),
          optgroup_header: (data, escape) => (
            `<div class="font-bold ml-2 my-2 p-3 text-2xl">${escape(data.label)}</div>`
          )
        }
      },
      create: {
        create: true,
        createOnBlur: true,
        persist: false,
        createFilter: function(input) {
          input = input.toLowerCase()
          const isInOptions = input.toLowerCase() in this.options
          const isEmail = Boolean(input.match(/.+\@.+\..+/))
          return !isInOptions && isEmail
        },
        render: {
          option_create: (data, escape) => (
            `<div class="create">${I18n.t('actions.add')} <strong>${escape(data.input)}</strong>&hellip;</div>`
          ),
          no_results: () => null,
        }
      },
      ajax: (select, url) => ({
        preload: true,
        openOnFocus: true,
        load: (query, callback) => {
          fetch(`${select.dataset.url || url}?q=${encodeURIComponent(query)}`)
            .then(res => res.json().then(callback))
            .catch(() => callback())
        }
      })
    }
  }
}

window.initTomSelect = (select, config) => {
  try {
    const tomSelect = new TomSelect(select, ConfigBuilder.call(select, config))
    config.lock && tomSelect.lock()

    return tomSelect
  } catch(e) {
    return select.tomSelect
  }
}
