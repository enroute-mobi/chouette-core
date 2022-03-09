import { flow } from 'lodash'
import ResourceMixin from '../operations/mixins/resource'
import CollectionMixin from '../operations/mixins/collection'

// Macro
const MacroMixin = superclass => class Macro extends superclass {
	get inputSelector() { return 'macros_attributes' }
}

export const Macro = flow(ResourceMixin, MacroMixin)(class {})

// Macro Collection
const MacroCollectionMixin = superclass => class MacroCollection extends superclass {
	static get ResourceConstructor() { return Macro }
}

export const MacroCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
