import TomSelect from 'tom-select'

document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll("[data-tomselect='true']").forEach(function(select) {
    if (!select.tomselect) {
      let plugin_list = []
      if (select.hasAttribute("multiple")) {
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

      if (Array.prototype.some.call(select.options, o => o.value === "" && o.text != "")) {
        settings.allowEmptyOption = true
      }
      
      new TomSelect(select, settings);
    }
  });

  document.querySelectorAll("[data-tomselect-ajax='true']").forEach(function(select) {
    if (!select.tomselect) {
      let plugin_list = []
      if (select.hasAttribute("multiple")) {
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
        sortField: [{field:'$order'},{field:'$score'}],
        load: function(query, callback) {
          const url = `${select.dataset.url}?q=${encodeURIComponent(query)}`;
          fetch(url)
            .then(response => response.json())
            .then(data => callback(data))
            .catch(() => callback());
        }
      };
      
      const initValue = select.dataset.initvalue;
      if (initValue) {
        try {
          const parsedInitValue = JSON.parse(initValue);
          if (parsedInitValue.id && parsedInitValue.text) {
            const option = new Option(parsedInitValue.text, parsedInitValue.id, true, true);
            select.add(option);
          }
        } catch (e) {
        }
      }
      
      new TomSelect(select, settings);
    }
  });
});
