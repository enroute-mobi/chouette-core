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
        plugins: ['clear_button']
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
          no_results: () => null
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
  if (!Boolean(select.tomselect)) { // if Tom Select has already been initialized on input it raises an error
    const tomSelect = new TomSelect(select, ConfigBuilder.call(select, config))

    config.lock && tomSelect.lock()
  }
}
