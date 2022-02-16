import { find, filter, omit, reject } from 'lodash'

const constructors = ['Macro', 'MacroContext']

export default superclass => class Collection extends superclass {
	constructor(...args) {
		super(...args)

		return new Proxy(this, {
			set(obj, prop, value) {
				if (constructors.includes(value.constructor.name)) {
					const index = parseInt(prop)
					const prevObject = obj[index - 1]
					const nextObject = obj[index + 1]

					value.position = index + 1 // Setting object's position based on index
					value.isFirst = !prevObject
					value.isLast = !value.isDeleted && (!nextObject || nextObject.isDeleted)
				}

				obj[prop] = value

				return true
			}
		})
	}

	get first() { return this[0] }

	get last() { return this[this.length - 1] }

	get active() { return reject(this, 'isDeleted') }

	get deleted() { return filter(this, 'isDeleted') }

	isEmpty() { return this.length === 0 }

	get(uuid) { return find(this, ['uuid', uuid]) }

	add(_attributes) {
		throw new Error('add function not implemented')
	}

	delete(index) {
		const object = this[index]

		if(!object) return false

		this.sendToBottom(index)
		object.delete()

		return true
	}

	restore(index) {
		const object = this[index]

		if (!object) return false

		object.restore()

		this.sendToBottomOfActiveResources(object)
	}

	duplicate(index) {
		const object = this[index]

		if (!object) return false

		const attributes = omit(Object.assign(object), ['id', 'uuid', 'errors', 'position', '_destroy'])

		this.add(attributes)
	}

	moveUp(index) {
		this.swap(index, index - 1)
	}

	moveDown(index) {
		this.swap(index, index + 1)
	}

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
