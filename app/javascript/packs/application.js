/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// import jQuery from 'jquery'
// import {} from 'jquery-ujs'
import "@fortawesome/fontawesome-free/css/all"
import '@ryangjchandler/spruce'
import 'alpinejs'
import TomSelect from 'tom-select'

window.initTomSelect = (selector, config) => {

  const { placeholder, multiple, minimumInputLength, ...rest } = config

  const selectConfig = {
    maxItems: multiple ? null : 1,
    shouldLoad: query => query.length >= minimumInputLength || 0,
    render: {
      option: (data, escape) => '<div>' + escape(data.text) + '</div>'
    },
    ...rest
  }

  return new TomSelect(selector, selectConfig)
}