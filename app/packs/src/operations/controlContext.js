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

	get attributes() { return omit(this, ['uuid', 'errors', 'html', 'controls']) }
}

export const ConrolContext = flow(ResourceMixin, ControlContextMixin)(class {})

// Control Context Collection
const ControlCollectionMixin = superclass => class ControlContextCollection extends superclass {
	static get ResourceConstructor() { return ConrolContext }

	duplicate(controlContext) {
		this
			.add(controlContext.attributes)
			.then(duplicate => {
				controlContext.controls.forEach(control => {
					duplicate.controls.add(control.attributes)
				})
			})
	}
}

export const MacroContextCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
