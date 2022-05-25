import Alpine from 'alpinejs'

import { FileInput, ValidityPeriodInput } from './form/inputs'

Alpine.data('documentForm', ({ filename, validityPeriod, errors }) => ({
	init() {
		const hasErrors = errors.length > 0
		this.inputs.set('file', new FileInput({ filename: hasErrors ? '' : filename, hasErrors }))
		this.inputs.set('validityPeriod', new ValidityPeriodInput(validityPeriod))

		errors.forEach(text => {
			Alpine.store('flash').add({ type: 'error', text })
		})

		if (Boolean(filename) && hasErrors) {
			Alpine.store('flash').add({ type: 'warning', text: 'Veuillez re-uploader votre fichier' })
		}
	},

	// Form
	inputs: new Map,
	onFormData({ formData }) {
		this.inputs.forEach(input => { input.onFormData(formData) })
	}
}))
