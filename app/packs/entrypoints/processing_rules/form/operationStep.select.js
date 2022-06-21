import Select from './base.select'

export default class OperationStepSelect extends Select {
	addOptions() {
		const isControlList = this.form.processableType === 'Control::List'
		this.options.forEach(option => {
			let shouldAdd = false

			switch (option.value) {
				case 'after_import':
				case 'before_merge':
					shouldAdd = true
					break
				case 'after_merge':
					shouldAdd = isControlList
					break
				case 'after_aggregate':
					shouldAdd = this.form.isWorkgroupOwner && isControlList
					break
			}

			shouldAdd && this.tomSelect.addOption({ id: option.value, text: option.innerText })
		})
	}

	reload() {
		super.reload()

		this.addOptions()
	}
}
