import TomSelect from 'tom-select'

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll('select.editable_select').forEach((el)=>{
    // test if el is a multiple select input
    let plugin_list = []
    if(el.hasAttribute("multiple")) {
      plugin_list = ['clear_button', 'remove_button']
    }
    else{
      plugin_list = ['clear_button']
    }

    let settings = {
      plugins: plugin_list,
      openOnFocus: true,
      createOnBlur: true,
      create: true
    }
    new TomSelect(el, settings)
  })
})

