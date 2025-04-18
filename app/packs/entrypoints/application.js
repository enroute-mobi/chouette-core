/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/packs and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//

// import 'core-js/stable'
// import 'regenerator-runtime/runtime'
const images = require.context('../images', true)
const imagePath = (name) => images(name, true)


import "@fortawesome/fontawesome-free/js/all"
import "src/sentry"

// Loading flag icons (Can't move in application.scss because I don't find a way to load load svg files in tags directory)
import 'flag-icon-css/css/flag-icons.css'

// Loading Alpine before every application javscript files
import Alpine from "alpinejs"
window.Alpine = Alpine

document.addEventListener("DOMContentLoaded", function(event) {
  window.Alpine.start();
});

//---------------------------
// Loaded after Alpine start
//---------------------------

import 'entrypoints/inputs/ajax_select'
import "src/flash_messages"
import "src/date_filters"
import "src/chartkick"
import "src/main_menu"
import "src/forms"

// React Apps
import './journey_patterns'
import './routes/form'
import './time_tables/edit'
import './vehicle_journeys'

import { i18n } from 'src/i18n'
window.I18n = i18n

console.log('Hello World from Webpacker 6')
