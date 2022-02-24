import { flow, omit } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'
import { ControlCollection } from './control'

// Control Context
const ControlContextMixin = superclass => class ConrolContext extends superclass {
	constructor({ macros, ...attributes }) {
		super(attributes)

		this.macros = new ControlCollection
	}

	get inputSelector() { return 'control_contexts_attributes' }

	get storeName() { return 'controlList' }
}

export const ConrolContext = flow(ResourceMixin, ControlContextMixin)(class {})

// Control Context Collection
const ControlCollectionMixin = superclass => class ControlContextCollection extends superclass {
	static get ResourceConstructor() { return ConrolContext }

	duplicate(macroContext) {
		const getAttributes = object => omit(Object.assign(object), ['id', 'uuid', 'errors', 'position', '_destroy'])

		this
			.add(getAttributes(macroContext))
			.then(duplicate => {
				macroContext.macros.forEach(macro => {
					duplicate.macros.add(getAttributes(macro))
				})
			})
	}
}

export const MacroContextCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
