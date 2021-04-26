import AjaxAutoComplete from '../../helpers/ajax_autocomplete'

window.form = () => ({
	type: '',
	exportedLines: '',
	referentialId: '',
	initForm() {
		this.referentialId = this.$refs.referentialIdSelect.value
		this.type = this.$refs.typeSelect.value

		// Need to use jquery here because the referentialIdSelect uses select2 (it does not work with the defauly alpine way)
		$(`#${this.$refs.referentialIdSelect.id}`).on('change', e => {
			this.referentialId = e.target.value
		})
	},
	initExportedLines() {
		console.log('initExportedLines')
		console.log(this.$refs.exportedLinesSelect.value)
	},
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

		new AjaxAutoComplete(
			selector, 
			{ ...defaultOptions, ...options }
		).init()
	}
})
