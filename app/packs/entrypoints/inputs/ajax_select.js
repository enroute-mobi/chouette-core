import TomSelect from 'tom-select'

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll('select.ajax_select').forEach((el)=>{
    let settings = {
      valueField: 'id',
      labelField: 'text',
      preload: true,
      plugins: ['clear_button'],
      openOnFocus: true,
      // fetch remote data
      load: function(query, callback) {
        var url = el.dataset.url + '?q=' + encodeURIComponent(query);
        fetch(url)
          .then(response => response.json())
          .then(callback)
          .catch(()=>{
            callback();
          })

      }
    }
    new TomSelect(el, settings)
  })
})

