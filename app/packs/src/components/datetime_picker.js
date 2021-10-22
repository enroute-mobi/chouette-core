import flatpickr from 'flatpickr'

flatpickr(".flatpickr", {
	locale: I18n.locale,
	dateFormat: "d/m/Y",
	allowInput: true,
	wrap: true
})

// flatpickr({
//     "plugins": [new rangePlugin({ input: "#secondRangeInput"})]
// });

flatpickr(".time_picker", {
	enableTime: true,
	noCalendar: true,
	dateFormat: "H:i",
	time_24hr: true
})
