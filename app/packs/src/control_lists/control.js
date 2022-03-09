import { flow } from 'lodash'
import ResourceMixin from '../operations/mixins/resource'
import CollectionMixin from '../operations/mixins/collection'

// Control
const ControlMixin = superclass => class Control extends superclass {
	constructor(attributes) {
		super(attributes)

		this.criticity = this.criticity || 'warning'
	}
	get inputSelector() { return 'controls_attributes' }
}

export const Control = flow(ResourceMixin, ControlMixin)(class {})

// Control Collection
const ControlCollectionMixin = superclass => class ControlCollection extends superclass {
	static get ResourceConstructor() { return Control }
}

export const ControlCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
