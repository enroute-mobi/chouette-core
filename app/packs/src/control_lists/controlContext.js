import { flow, omit } from 'lodash'
import ResourceMixin from '../operations/mixins/resource'
import CollectionMixin from '../operations/mixins/collection'
import { ControlCollection } from './control'
import { nodeId } from '../operations/helpers'

// Control Context
const ControlContextMixin = superclass => class ControlContext extends superclass {
	constructor({ macros, ...attributes }) {
		super(attributes)

		this.controls = new ControlCollection
	}

	get inputSelector() { return 'control_contexts_attributes' }

	get attributesList() { return ['errors', 'html', 'controls'] }
}

export const ControlContext = flow(ResourceMixin, ControlContextMixin)(class {})

// Control Context Collection
const ControlCollectionMixin = superclass => class ControlContextCollection extends superclass {
	static get ResourceConstructor() { return ControlContext }

	static nodeIdGenerator = nodeId('control-context')

	duplicate(controlContext) {
		const build = object => omit(object.attributes, 'id')
		return this
			.add(build(controlContext))
			.then(duplicate => {
				controlContext.controls.forEach(control => {
					duplicate.controls.add(build(control))
				})
			})
	}
}

export const ControlContextCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
