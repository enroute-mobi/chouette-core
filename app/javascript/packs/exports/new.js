// import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

window.Spruce.store('export', {
	type: '',
	exportedLines: 'all_line_ids',
	referentialId: '',
	updateReferentialId(value) {
		this.referentialId = value
	},
	updateExportType(value) {
		this.type = value
	},
	updateExportedLines(value) {
		this.exportedLines = value
	}
})

window.form = () => ({
	// type: '',
	// exportedLines: '',
	// referentialId: '',
	// initForm() {
	// 	this.referentialId = this.$refs.referentialIdSelect.value
	// 	this.type = this.$refs.typeSelect.value
	// 	if (!!this.$refs.exportedLinesSelect) {
	// 		this.exportedLines = this.$refs.exportedLinesSelect .value
	// 	}
	// },
	// initExportedLines() {
	// 	console.log('initExportedLines')
	// 	console.log(this.$refs.exportedLinesSelect.value)
	// },
	watchExportedLines(currentValue, referentialId) {
		const defaultOptions = {
			minimumInputLength: 0,
			allowClear: true,
			multiple: true
		}

		let selector, options
		switch(currentValue) {
			case 'line_ids':
				selector = '#export_line_ids'
				options = { placeholder: I18n.t('exports.form.line_name'), ajax: { url: `/referentials/${referentialId}/autocomplete/lines` } }
				break
			case 'company_ids':
				selector = '#export_line_ids'
				options = { placeholder: I18n.t('exports.form.line_name') }
				break
			case 'line_provider_ids':
				selector = '#export_line_ids'
				options = { placeholder: I18n.t('exports.form.line_name') }
				break
		}

		// new AjaxAutoComplete(
		// 	selector, 
		// 	{ ...defaultOptions, ...options }
		// ).init()
	}
})
