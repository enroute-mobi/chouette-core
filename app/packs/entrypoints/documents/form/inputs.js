export class ValidityPeriodInput {
	constructor({ validAfter, validUntil }) {
		this.validAfter = validAfter || ''
		this.validUntil = validUntil || ''
	}

	get value () {
		return `[${this.validAfter},${this.validUntil}]`
	}

	onFormData(_formData) {}
}

export class FileInput {
	constructor({ filename, hasErrors }) {
		this.hasFile = Boolean(filename)
		this.shouldUploadFile = false

		if (this.hasFile && !hasErrors) {
			const dt = new DataTransfer()
			dt.items.add(new File([''], filename))

			this.node.files = dt.files
		}

		this.label = this.getLabel()
	}

	get node() {
		return document.getElementById('document_file')
	}

	get file() {
		return this.node.files[0]
	}

	getLabel() {
		return this.hasFile ? this.file.name : I18n.t('documents.form.placeholders.select_file')
	}

	openFileDialog() {
		this.node.click()
	}

	onUpload(e) {
		this.hasFile = true
		this.label = this.getLabel()
		this.shouldUploadFile = true
	}

	onRemove() {
		this.node.value = null
		this.node.files = new DataTransfer().files

		this.hasFile = false
		this.label = this.getLabel()
	}

	onFormData(formData) {
		!this.shouldUploadFile && formData.delete('document[file]')
	}
}
