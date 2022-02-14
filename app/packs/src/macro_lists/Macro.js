import { omit } from 'lodash'
import HTMLFinder from './HTMLFinder'

export default class Macro {
	constructor(attributes) {
		this.uuid = crypto.randomUUID()
		this._destroy = false
		this.errors = []
	
		for (const key in attributes) {
			this[key] = attributes[key]
		}
	}

	static from(macro) {
		const attributes = omit(Object.assign(macro), ['id', 'uuid', 'errors', '_destroy'])
		return new Macro(attributes)
	}

	get isDeleted() { return this._destroy }

	get hasErrors() { return this.errors.length > 0 }

	delete () {
		this._destroy = true
	}

	restore() {
		this._destroy = false
	}

	getHTML(index) { 
		return new HTMLFinder({ index, macro: this }).render()
	}
}
