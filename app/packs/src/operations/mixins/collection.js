import { find, filter, first, isEmpty, last, omit, reject } from 'lodash'

export default superclass => class Collection extends superclass {
	static get ResourceConstructor() { throw new Error('ResourceConstructor not implemented') }

	get first() { return first(this) }

	get last() { return last(this) }

	get active() { return reject(this, 'isDeleted') }

	get deleted() { return filter(this, 'isDeleted') }

	isEmpty() { return isEmpty(this) }

	get(uuid) { return find(this, ['uuid', uuid]) }

	add(attributes) {
		const resource = new this.constructor.ResourceConstructor(attributes)

		this.push(resource)

		return Promise.resolve(resource)
	}

	delete(object, index) {
		this.sendToBottom(index)
		object.delete()
	}

	restore(object) {
		object.restore()
		this.sendToBottomOfActiveResources(object)
	}

	duplicate(object) {
		this.add(omit(object.attributes, ['id', 'uuid', '_destroy']))
	}

	moveUp(index) { this.swap(index, index - 1) }

	moveDown(index) { this.swap(index, index + 1) }

	sendToTop(index) {
		do { this.moveUp(index); index -= 1 } while (index > 0)
	}

	sendToBottom(index) {
		do { this.moveDown(index); index += 1 } while (index < this.length - 1)
	}

	swap(indexA, indexB) {
		if (!!this[indexA] && !!this[indexB]) {
			[this[indexA], this[indexB]] = [this[indexB], this[indexA]]
		}
	}

	sendToBottomOfActiveResources(object) {
		this.splice(
			0,
			this.length,
			...[
				...reject(this.active, ['uuid', object.uuid]),
				object,
				...this.deleted
			]
		)
	}
}
