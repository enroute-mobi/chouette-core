import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'

// Control
const ControlMixin = superclass => class Control extends superclass {
	get inputSelector() { return 'controls_attributes' }
}

export const Control = flow(ResourceMixin, ControlMixin)(class {})

// Control Collection
const ControlCollectionMixin = superclass => class ControlCollection extends superclass {
	static get ResourceConstructor() { return Control }
}

export const ControlCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
