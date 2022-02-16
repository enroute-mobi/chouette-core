import Alpine from 'alpinejs'
import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'

// Macro
const MacroMixin = superclass => class Macro extends superclass {
	constructor(attributes) {
		super(attributes)

		this.macroContextUUID = null
	}

	get fetchHTMLPath() { return '/fetch_macro_html' }

	get input() {
		const index = this.position - 1
		const contextIndex = this.macroContext?.position - 1
		const belongToContext = Boolean(this.macroContextUUID)

		return {
			selector: 'macros_attributes',
			replaceName: (belongToContext ? `[macro_contexts_attributes][${contextIndex}]` : '') + `[macros_attributes][${ index }]`,
			replaceId: (belongToContext ? `macro_contexts_attributes_${contextIndex}_` : '')  + `macros_attributes_${index}`
		}
	}

	get macroContext() {
		return Alpine.store('macroList').macroContexts.get(this.macroContextUUID)
	}
}

export const Macro = flow(ResourceMixin, MacroMixin)(class {})

// Macro Collection
const MacroCollectionMixin = superclass => class MacroCollection extends superclass {
	add(attributes) {
		this.push(new Macro(attributes))
	}
}

export const MacroCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
