import TomSelect from 'tom-select'

export default class Select {
	constructor(form, xRef) {
		this.form = form
		this.select = form.$refs[xRef]
		this.tomSelect = new TomSelect(
			this.select,
			{
				valueField: 'id',
				labelField: 'text',
				plugins: ['clear_button'],
				openOnFocus: true,
				...this.params
			}
		)
		this.options = this.select.querySelectorAll('option')

		this.handleDisable()
	}

	reload() {
		this.resetOptions()
		this.handleDisable()
	}

	handleDisable() {
		this.form.hasProcessableType() ? this.tomSelect.enable() : this.tomSelect.disable()
	}

	resetOptions() {
		this.tomSelect.clear()
		this.tomSelect.clearOptions()
	}

	get params() {
		return {}
	}
}
