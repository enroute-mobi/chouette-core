import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'
import { MacroCollection } from './macro'

// Macro Context
const MacroContextMixin = superclass => class MacroContext extends superclass {
	constructor({ macros, ...attributes}) {
		super(attributes)

		this.macros = new Proxy(new MacroCollection(), {
			set: (obj, prop, value) => {
				if (value.constructor.name === 'Macro') {
					value.macroContextUUID = this.uuid
				}

				obj[prop] = value

				return true
			}
		})
	}

	get input() {
		const index = this.position - 1
		return {
			selector: 'macro_contexts_attributes',
			replaceName: `[macro_contexts_attributes][${index}]`,
			replaceId: `macro_contexts_attributes_${index}`
		}
	}
}

export const MacroContext = flow(ResourceMixin, MacroContextMixin)(class {})

// Macro Context Collection
const MacroCollectionMixin = superclass => class MacroContextCollection extends superclass {
	add(attributes, callback = () => {}) {
		const macroContext = new MacroContext(attributes)
		this.push(macroContext)

		callback(macroContext)
	}
}

export const MacroContextCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
