import flatpickr from "flatpickr"
import { French } from "flatpickr/dist/l10n/fr.js"
import { english } from "flatpickr/dist/l10n/default.js"

const locales = {
  fr: French,
  en: english
}

const dateConfig = {
  dateFormat: "d/m/Y",
  wrap: true
}

const timeConfig = {
  enableTime: true,
  noCalendar: true,
  dateFormat: "H:i",
  time_24hr: true,
  wrap: true
}

// Idempotent init: only attaches flatpickr to blocks not initialized yet, so it
// can safely run again when new pickers enter the DOM (cocoon insert, Alpine x-if).
function initDatePickers() {
  document.querySelectorAll(".date_picker_block").forEach((el) => {
    if (!el._flatpickr) {
      flatpickr(el, { locale: locales[I18n.locale], ...dateConfig })
    }
  })

  document.querySelectorAll(".time_picker_block").forEach((el) => {
    if (!el._flatpickr) flatpickr(el, timeConfig)
  })
}

document.addEventListener("DOMContentLoaded", initDatePickers)

// Allows dynamically-revealed pickers (e.g. Alpine x-if blocks) to request an init.
document.addEventListener("flatpickr:refresh", initDatePickers)

$('.simple_form').on('cocoon:after-insert', initDatePickers)
