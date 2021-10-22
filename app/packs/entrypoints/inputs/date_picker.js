import flatpickr from "flatpickr"
import 'flatpickr/dist/flatpickr.css'
import { French } from "flatpickr/dist/l10n/fr.js";
import { english } from "flatpickr/dist/l10n/default.js"

const locales = {
	fr: French,
	en: english
}

flatpickr('.flatpickr', {
	locale: locales[I18n.locale],
	dateFormat: "d/m/Y",
	allowInput: true,
	wrap: true
})

flatpickr(".time_picker", {
	enableTime: true,
	noCalendar: true,
	dateFormat: "H:i",
	time_24hr: true
})
