import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'

// Macro
const MacroMixin = superclass => class Macro extends superclass {
	get storeName() { return 'macroList' }

	get inputSelector() { return 'macros_attributes' }
}

export const Macro = flow(ResourceMixin, MacroMixin)(class {})

// Macro Collection
const MacroCollectionMixin = superclass => class MacroCollection extends superclass {
	static get ResourceConstructor() { return Macro }
}

export const MacroCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
