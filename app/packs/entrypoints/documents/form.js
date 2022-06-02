import Alpine from 'alpinejs'

Alpine.data('documentForm', ({ errors }) => ({
	init() {
		errors.forEach(text => {
			Alpine.store('flash').add({ type: 'error', text })
		})
	}
}))

Alpine.data('fileInput', ({ filename }) => ({
	init() {
		this.filename = filename
	},
	get node() {
		return document.getElementById('document_file')
	},
	get file() {
		return this.node.files[0]
	},
	getLabel() {
		return Boolean(this.filename) ? this.filename : I18n.t('documents.form.placeholders.select_file')
	},
	openFileDialog() {
		this.node.click()
	}
}))

Alpine.data('validityPeriodInput', ({ validityPeriod }) => ({
	validAfter: validityPeriod.validAfter || '',
	validUntil: validityPeriod.validUntil || '',
	getValue() {
		return `[${this.validAfter},${this.validUntil}]`
	}
}))
