import { addResourceToCollection, FormDataUpdater } from '../operations/helpers'
import { MacroCollection } from './macro'
import { MacroContextCollection } from './macroContext'

export default class Store {
	constructor() {
		this.name = ''
		this.comments = ''
		this.macros = new MacroCollection() 
		this.contexts = new MacroContextCollection()

		this.addMacros = addResourceToCollection('macros')
	}
	
	initState({ name, comments, macros, macro_contexts, is_show }) {
		this.name = name
		this.comments = comments
		this.isShow = is_show

		this.addMacros(macros)(this)

		macro_contexts.forEach(({ macros, ...attributes }) => {
			this.contexts.add(attributes).then(this.addMacros(macros))
		})
	}
	setFormData({ formData }) {
		const formDataUpdater = new FormDataUpdater(formData, 'macro_list')
	
		formData.set('macro_list[name]', this.name || '')
		formData.set('macro_list[comments]', this.comments || '')

		this.contexts.forEach((c, i) => {
			formDataUpdater.call()(c, i)

			c.macros.forEach(formDataUpdater.call(`[macro_contexts_attributes][${i}]`))
		})

		this.macros.forEach(formDataUpdater.call())
	}
}
