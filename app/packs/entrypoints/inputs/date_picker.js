import flatpickr from "flatpickr"
import { French } from "flatpickr/dist/l10n/fr.js"
import { english } from "flatpickr/dist/l10n/default.js"

const locales = {
	fr: French,
	en: english
}

document.addEventListener("DOMContentLoaded", () => {
  if (document.getElementsByClassName("flatpickr")) {
    flatpickr('.date_picker_block', {
			locale: locales[I18n.locale],
      dateFormat: "d/m/Y",
      wrap: true
    })
  }

  if (document.getElementsByClassName("time_picker")) {
    flatpickr(".time_picker_block", {
			enableTime: true,
			noCalendar: true,
			dateFormat: "H:i",
			time_24hr: true,
			wrap: true
		})
  }
})

$('.simple_form').on('cocoon:after-insert', function(e, insertedItem, originalEvent) {
  flatpickr(".time_picker_block", {
    enableTime: true,
    noCalendar: true,
    dateFormat: "H:i",
    time_24hr: true,
    wrap: true
  })
});