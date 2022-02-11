import { findIndex, omit } from 'lodash'
import HTMLFinder from './HTMLFinder'

export default class Macro {
	constructor(attributes) {
		this.uuid = crypto.randomUUID()
		this.isDeleted = false

		for (const key in attributes) {
			this[key] = attributes[key]
		}
	}

	static from(macro) {
		const attributes = omit(Object.assign(macro), ['id', 'uuid', 'isDeleted'])
		return new Macro(attributes)
	}

	get position() {
		return findIndex(this.store.macros, ['uuid', this.uuid]) + 1
	}

	isFirst() {
		return this.position === 1
	}

	isLast() {
		return this.position == this.store.activeMacros().length
	}

	delete () {
		this.isDeleted = true
	}

	restore() {
		this.isDeleted = false
	}

	getHTML(index) {
		return new HTMLFinder(this.id, this.type, index).render()
	}
}
