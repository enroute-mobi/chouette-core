import { Select } from '../../inputs/tom_select'
export default class BaseSelect extends Select {
	constructor(selectId, form) {
		super(selectId)

		this.form = form

		this.handleDisable()
	}

	reload() {
		this.resetOptions()
		this.handleDisable()
	}

	handleDisable() {
		this.form.hasProcessableType() ? this.tomSelect.enable() : this.tomSelect.disable()
	}
}
