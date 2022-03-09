import { flow } from 'lodash'
import ResourceMixin from '../operations/mixins/resource'
import CollectionMixin from '../operations/mixins/collection'
import { MacroCollection } from './macro'

// Macro Context
const MacroContextMixin = superclass => class MacroContext extends superclass {
	constructor({ macros, ...attributes }) {
		super(attributes)

		this.macros = new MacroCollection
	}

	get inputSelector() { return 'macro_contexts_attributes' }

	get attributesList() { return ['errors', 'html', 'macros'] } 
}

export const MacroContext = flow(ResourceMixin, MacroContextMixin)(class {})

// Macro Context Collection
const MacroCollectionMixin = superclass => class MacroContextCollection extends superclass {
	static get ResourceConstructor() { return MacroContext }

	duplicate(macroContext) {		
		return this
			.add(macroContext.attributes)
			.then(duplicate => {
				macroContext.macros.forEach(macro => {
					duplicate.macros.add(macro.attributes)
				})
			})
	}
}

export const MacroContextCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
