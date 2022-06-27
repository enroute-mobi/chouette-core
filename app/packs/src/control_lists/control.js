import { flow } from 'lodash'
import ResourceMixin from '../operations/mixins/resource'
import CollectionMixin from '../operations/mixins/collection'
import { nodeId } from '../operations/helpers'

// Control
const ControlMixin = superclass => class Control extends superclass {
	constructor(attributes) {
		super(attributes)

		this.criticity = this.criticity || 'warning'
	}
	get inputSelector() { return 'controls_attributes' }

	renderClassDescription(expanded, text) {
		const domParser = new DOMParser()
		const parse = string => domParser.parseFromString(string, 'text/html').body.childNodes[0]

		let color

		switch(this.criticity) {
			case 'warning':
				color = '#ed7f00'
				break
			case 'error':
				color = '#da2f36'
				break
		}

		const container = parse('<div class="flex w-full items-center"></div>')
		const criticity = parse(`<span class="fa fa-circle mr-xs" style="color:${color};"></span>`)
		const name = parse(`<div>${this.name}</div>`)
		const description = parse(`<div class="ml-auto human_model_name">${expanded ? text : '('+ text +')' }</div>`)

		container.appendChild(criticity)
		container.appendChild(description)

		return container.outerHTML
	}

	get criticityIcon() {
		return
	}
}

export const Control = flow(ResourceMixin, ControlMixin)(class {})

// Control Collection
const ControlCollectionMixin = superclass => class ControlCollection extends superclass {
	static get ResourceConstructor() { return Control }

	static nodeIdGenerator = nodeId('control')
}

export const ControlCollection = flow(CollectionMixin, ControlCollectionMixin)(Array)
