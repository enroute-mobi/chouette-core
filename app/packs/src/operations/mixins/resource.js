import { omit } from 'lodash'
import HTMLFinder from '../helpers/HTMLFinder'

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

	get isDeleted() { return this._destroy }

	get hasErrors() { return this.errors.length > 0 }

	get attributes() { return omit(Object.assign(this), ['uuid', 'errors', 'html']) }

	delete() { this._destroy = true }

	restore() { this._destroy = false }

	getHTML(index) { return new HTMLFinder(index, this).render() }
}
