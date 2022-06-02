import { addResourceToCollection, FormDataUpdater } from '../operations/helpers'
import { ControlCollection } from './control'
import { ControlContextCollection } from './controlContext'

export default class Store {
	constructor() {
		this.name = ''
		this.comments = ''
		this.shared = false
		this.controls = new ControlCollection()
		this.contexts = new ControlContextCollection()

		this.addControls = addResourceToCollection('controls')
	}

	initState({ name, comments, shared, controls, control_contexts, is_show }) {
		this.name = name
		this.comments = comments
		this.shared = shared
		this.isShow = is_show

		this.addControls(controls)(this)

		control_contexts.forEach(({ controls, ...attributes }) => {
			this.contexts.add(attributes).then(this.addControls(controls))
		})
	}

	setFormData({ formData }) {
		const formDataUpdater = new FormDataUpdater(formData, 'control_list')

		formData.set('control_list[name]', this.name || '')
		formData.set('control_list[comments]', this.comments || '')
		formData.set('control_list[shared]', this.shared || false)

		this.contexts.forEach((c, i) => {
			formDataUpdater.call()(c, i)

			c.controls.forEach(formDataUpdater.call(`[control_contexts_attributes][${i}]`))
		})

		this.controls.forEach(formDataUpdater.call())
	}
}
