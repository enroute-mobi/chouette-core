import { omit } from 'lodash'
import HTMLFinder from '../HTMLFinder'

export default superclass => class Resource extends superclass {
	constructor(attributes) {
		super(attributes)

		this.uuid = crypto.randomUUID()
		this._destroy = false
		this.errors = []

		for (const key in attributes) {
			this[key] = attributes[key]
		}
	}

	static from(object) {
		return omit(Object.assign(object), ['id', 'uuid', 'errors', 'position', '_destroy'])
	}

	get isDeleted() { return this._destroy }

	get hasErrors() { return this.errors.length > 0 }

	delete() {
		this._destroy = true
	}

	restore() {
		this._destroy = false
	}

	getHTML(index) {
		return new HTMLFinder(index, this).render()
	}
}
