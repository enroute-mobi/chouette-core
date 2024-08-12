import TomSelect from 'tom-select'

document.addEventListener("DOMContentLoaded", () => {
  addAjaxSelectToForm(document)
})

function addAjaxSelectToForm(dom_part) {
  dom_part.querySelectorAll('select.ajax_select').forEach((el) => {
    let plugin_list = []
    if (el.hasAttribute("multiple")) {
      plugin_list = ['clear_button', 'remove_button']
    }
    else {
      plugin_list = ['clear_button']
    }

    let settings = {
      valueField: 'id',
      labelField: 'text',
      preload: true,
      plugins: plugin_list,
      openOnFocus: true,
      // fetch remote data
      load: function (query, callback) {
        var url = el.dataset.url + '?q=' + encodeURIComponent(query);
        fetch(url)
          .then(response => response.json())
          .then(callback)
          .catch(() => {
            callback();
          })
      }
    }

    if (el.hasAttribute("data-ajax-html")) {
      settings.render = {
        option: function(data) {
          return '<div>' + data.text + '</div>';
        },
        item: function(data) {
          return data.text
        }
      }
    }

    new TomSelect(el, settings)
  })
}

window.addAjaxSelectToForm = addAjaxSelectToForm
