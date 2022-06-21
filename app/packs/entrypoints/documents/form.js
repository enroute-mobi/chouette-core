import Alpine from 'alpinejs'

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
