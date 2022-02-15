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

	get macroContext() {
		return this.store.macroContexts.find(this.macroContextUUID)
	}
}

export const Macro = flow(ResourceMixin, MacroMixin)(class {})

// Macro Collection
const MacroCollectionMixin = superclass => class MacroCollection extends superclass {
	add(attributes) {
		this.push(new Macro({ ...attributes, store: this.store }))
	}
}

export const MacroCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
