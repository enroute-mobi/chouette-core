import { flow } from 'lodash'
import ResourceMixin from './mixins/resource'
import CollectionMixin from './mixins/collection'
import { MacroCollection } from './macro'

// Macro Context
const macroContextMixin = superclass => class MacroContext extends superclass {
	constructor(attributes) {
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

	get fetchHTMLPath() { return '/fetch_macro_context_html' }

	get input() {
		const index = this.position - 1
		return {
			selector: 'macro_contexts_attributes',
			replaceName: `[macro_contexts_attributes][${index}]`,
			replaceId: `macro_contexts_attributes_${index}`
		}
	}

	get inputBasename() { return 'macro_contexts_attributes' }
}

export const MacroContext = flow(ResourceMixin, macroContextMixin)(class {})

// Macro Context Collection
const MacroCollectionMixin = superclass => class MacroContextCollection extends superclass {
	add(attributes) {
		this.push(new MacroContext(attributes))
	}
}

export const MacroContextCollection = flow(CollectionMixin, MacroCollectionMixin)(Array)
