import { filter, first, isEmpty, last, omit, reject } from 'lodash'
import ResourceMixin from './resource'

const Resource = ResourceMixin(class {})
export default superclass => class Collection extends superclass {
	static get ResourceConstructor() { return Resource }

	static get resourceName() { return this.ResourceConstructor.name.toLowerCase() }

	get first() { return first(this) }

	get last() { return last(this) }

	get active() { return reject(this, 'isDeleted') }

	get deleted() { return filter(this, 'isDeleted') }

	get isEmpty() { return isEmpty(this) }

	add(attributes) {
		const { value: nodeId } = this.constructor.nodeIdGenerator.next()
		const resource = new this.constructor.ResourceConstructor({ ...attributes, nodeId })

		this.push(resource)

		return Promise.resolve(resource)
	}

	delete(object, index) {
		this.sendToBottom(index)
		object.delete()
	}

	restore(object) {
		const activeObjects = this.active
		object.restore()

		this.splice(
			0,
			this.length,
			...[...activeObjects, object, ...this.deleted]
		)
	}

	duplicate(object) {
		this.add(omit(object.attributes, ['id', '_destroy']))
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
}
