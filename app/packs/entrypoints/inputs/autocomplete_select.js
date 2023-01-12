import TomSelect from 'tom-select'

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll('select.autocomplete_select').forEach((el)=>{
    let settings = {
      plugins: ['clear_button'],
      openOnFocus: true
    }
    new TomSelect(el, settings)
  })
})

