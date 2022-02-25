import Alpine from 'alpinejs'
import { get, isArray } from 'lodash'

import { MacroCollection } from '../../src/operations/macro'
import { MacroContextCollection } from '../../src/operations/macroContext'

Alpine.store('macroList', {
	isShow: false,
	name: '',
	comments: '',
	macros: new MacroCollection(),
	contexts: new MacroContextCollection(),
	initState({ name, comments, macros, macro_contexts }) {
		this.name = name
		this.comments = comments

		macros.forEach(macroAttributes => this.macros.add(macroAttributes))

		macro_contexts.forEach(({ macros, ...macroContextAttributes }) => {
			this.contexts
				.add(macroContextAttributes)
				.then(macroContext => {
					if (isArray(macros)) {
						for (const macroAttributes of macros) {
							macroContext.macros.add(macroAttributes)
						}
					}
				})
		})
	},
	setFormData({ formData }) {
		// We had some issues to keep store & form in sync. Especially during edit where we had conflicts between subforms.
		// As a solution we decided to compute manually the formData.
		for (const [key] of [...formData]) { /^macro/.test(key) && formData.delete(key) } // Reset all macro related fields

		const setFormDataForObject = (parentName = '') => (object, index) => {
			const getName = key => `macro_list${parentName}[${object.inputSelector}][${index}][${key}]`

			for (const key in object.attributes) {
				formData.set(getName(key), get(object, key, ''))
			}

			formData.set(getName('position'), index + 1)
		}

		formData.set('macro_list[name]', this.name || '')
		formData.set('macro_list[comments]', this.comments || '')

		this.contexts.forEach((c, i) => {
			setFormDataForObject()(c, i)

			c.macros.forEach(setFormDataForObject(`[macro_contexts_attributes][${i}]`))
		})

		this.macros.forEach(setFormDataForObject())
	}
})
