import flatpickr from "flatpickr"
import { French } from "flatpickr/dist/l10n/fr.js"
import { english } from "flatpickr/dist/l10n/default.js"

const locales = {
	fr: French,
	en: english
}

document.addEventListener("DOMContentLoaded", () => {
  if (document.getElementsByClassName("flatpickr")) {
    flatpickr('.flatpickr', {
	  locale: locales[I18n.locale],
      dateFormat: "d/m/Y",
      wrap: true
    })
  }

  if (document.getElementsByClassName("time_picker")) {
    flatpickr(".time_picker", {
			enableTime: true,
			noCalendar: true,
			dateFormat: "H:i",
			time_24hr: true,
			wrap: true
		})
  }
})
