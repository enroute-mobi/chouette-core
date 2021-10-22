import TomSelect from 'tom-select'
class ConfigBuilder {
  static call(select) {
    const { config, url } = select.dataset 

    const { type, ...payload } = JSON.parse(config)
    
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
        labelField: 'text'
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
      ajax(select, url) {
        return {
          preload: Boolean(url),
          openOnFocus: true,
          load: (query, callback) => {
            const { url } = select.dataset

            fetch(`${url}?q=${encodeURIComponent(query)}`)
              .then(res => res.json().then(callback))
              .catch(() => callback())
          },
        }
      }
    }
  }
}

window.initTomSelect = id => {
  const select = document.getElementById(id)

  if (!Boolean(select.tomselect)) { // if Tom Select has already been initialized on input it raises an error
    new TomSelect(select, ConfigBuilder.call(select))
  }
}
