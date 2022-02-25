import { isArray } from 'lodash'

import { MacroCollection } from './macro'
import { MacroContextCollection } from './macroContext'

const addMacros = macros => object => {
	isArray(macros) && macros.forEach(attributes => object.macros.add(attributes))
}

const formDataSetter = formData => (parentName = '') => (object, index) => {
	const getName = key => `macro_list${parentName}[${object.inputSelector}][${index}][${key}]`

	for (const key in object.attributes) {
		formData.set(getName(key), object[key])
	}

	formData.set(getName('position'), index + 1)
}

export default {
	name: '',
	comments: '',
	macros: new MacroCollection(),
	contexts: new MacroContextCollection(),
	initState({ name, comments, macros, macro_contexts }) {
		this.name = name
		this.comments = comments

		addMacros(macros)(this)

		macro_contexts.forEach(({ macros, ...attributes }) => {
			this.contexts.add(attributes).then(addMacros(macros))
		})
	},
	setFormData({ formData }) {
		// We had some issues to keep store & form in sync. Especially during edit where we had conflicts between subforms.
		// As a solution we decided to compute manually the formData.
		for (const [key] of [...formData]) { /^macro/.test(key) && formData.delete(key) } // Reset all macro related fields

		const setFormDataForObject = formDataSetter(formData)

		formData.set('macro_list[name]', this.name || '')
		formData.set('macro_list[comments]', this.comments || '')

		this.contexts.forEach((c, i) => {
			setFormDataForObject()(c, i)

			c.macros.forEach(setFormDataForObject(`[macro_contexts_attributes][${i}]`))
		})

		this.macros.forEach(setFormDataForObject())
	}
}
