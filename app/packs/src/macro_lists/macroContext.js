import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'
import { MacroCollection } from './macro'

// Macro Context
const macroContextMixin = superclass => class extends superclass {
	constructor(attributes) {
		super(attributes)

		this.macros = new MacroCollection()
	}

	get fetchHTMLPath() { return '/fetch_macro_context_html' }
}

export const MacroContext = flow(ResourceMixin, macroContextMixin)(class {})

// Macro Context Collection
const MacroCollectionMixin = superclass => class MacroContextCollection extends superclass {
	add(attributes) {
		this.push(new MacroContext({ ...attributes, store: this.store }))
	}
}

export const MacroContextCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
