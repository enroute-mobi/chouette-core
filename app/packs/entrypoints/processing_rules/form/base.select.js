import '../../inputs/tom_select'
export default class Select {
	constructor(form, selectId) {
		this.form = form
		this.select = document.getElementById(selectId)

		this.select.classList.remove('form-control')
		this.tomSelect = initTomSelect(this.select, this.params)
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
