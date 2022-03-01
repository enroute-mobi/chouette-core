import { range } from 'lodash'

import CollectionMixin from '../../../app/packs/src/operations/mixins/collection'

const Collection = CollectionMixin(Array)

describe('ResourceConstructor', () => {
	it('should return Resource', () => {
		expect(Collection.ResourceConstructor.name).toEqual('Resource')
	})
})

describe('add', () => {
	set('collection', () => new Collection)

	it('should add a Resource prototype to the collection', () => {
		collection.add({ name: 'test' })

		expect(collection).toHaveLength(1)
		expect(collection.first.constructor.name).toEqual('Resource')
	})
})

describe('delete', () => {
	set('collection', () => new Collection)
	set('resource', () => collection.first)

	beforeEach(() => {
		range(1, 3).forEach(i => collection.add({ name: `test${i}` }))

		collection.delete(resource, 0)
	})

	it('should still have same number of items', () => {
		expect(collection).toHaveLength(2)
	})

	it('should set isDeleted to true', () => {
		expect(resource.isDeleted).toBeTruthy()
	})

	it('should send deleted resource to bottom of collection', () => {
		expect(collection.last).toEqual(resource)
		expect(collection.first.name).toEqual('test2')
	})
})

describe('restore', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection[1])

	beforeEach(() => {
		range(1, 4).forEach(i => collection.add({ name: `test${i}` }))

		collection.delete(first, 0)
		collection.delete(second, 0)

		collection.restore(first)
	})

	it('should set isDeleted to false', () => {
		expect(first.isDeleted).toBeFalsy()
	})

	it('should send restored resource to bottom of active items', () => {
		expect(collection[1]).toEqual(first)
	})
})

describe('duplicate', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)

	beforeEach(() => {
		collection.add({ id: 1, name: 'test1', comments: 'foo' })

		collection.duplicate(first)
	})

	it('should add a copy of the chosen resource', () => {
		expect(collection).toHaveLength(2)
		expect(collection.last.name).toEqual('test1')
		expect(collection.last.comments).toEqual('foo')
	})

	it('should not copy item id', () => {
		expect(collection.last.id).toBeUndefined()
	})
})

describe('moveUp', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection.last)

	beforeEach(() => {
		range(1, 3).forEach(i => collection.add({ name: `test${i}` }))
	})

	it('should move up the selected item', () => {
		collection.moveUp(1)
		expect(collection.first.name).toEqual('test2')
		expect(collection.last.name).toEqual('test1')
	})

	it('should do nothing if item is already first', () => {
		collection.moveUp(0)
		expect(collection.first.name).toEqual('test1')
		expect(collection.last.name).toEqual('test2')
	})
})

describe('moveDown', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection.last)

	beforeEach(() => {
		range(1, 3).forEach(i => collection.add({ name: `test${i}` }))
	})

	it('should move down the selected item', () => {
		collection.moveDown(0)
		expect(collection.first.name).toEqual('test2')
		expect(collection.last.name).toEqual('test1')
	})

	it('should do nothing if item is already last', () => {
		collection.moveDown(1)
		expect(collection.first.name).toEqual('test1')
		expect(collection.last.name).toEqual('test2')
	})
})

describe('sendToTop', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection[1])
	set('third', () => collection.last)

	beforeEach(() => {
		range(1, 4).forEach(i => collection.add({ name: `test${i}` }))
	})

	it('should send the selected item to the top of collection', () => {
		collection.sendToTop(2)
		expect(collection.first.name).toEqual('test3')
		expect(collection[1].name).toEqual('test1')
		expect(collection.last.name).toEqual('test2')
	})

	it('should do nothing if item is already first', () => {
		collection.sendToTop(0)
		expect(collection.first.name).toEqual('test1')
		expect(collection[1].name).toEqual('test2')
		expect(collection.last.name).toEqual('test3')
	})
})

describe('sendToBottom', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection[1])
	set('third', () => collection.last)

	beforeEach(() => {
		range(1, 4).forEach(i => collection.add({ name: `test${i}` }))
	})

	it('should send the selected item to the end of collection', () => {
		collection.sendToBottom(0)
		expect(collection.first.name).toEqual('test2')
		expect(collection[1].name).toEqual('test3')
		expect(collection.last.name).toEqual('test1')
	})

	it('should do nothing if item is already last', () => {
		collection.sendToBottom(2)
		expect(collection.first.name).toEqual('test1')
		expect(collection[1].name).toEqual('test2')
		expect(collection.last.name).toEqual('test3')
	})
})

describe('active', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection[1])
	set('third', () => collection.last)

	beforeEach(() => {
		range(1, 4).forEach(i => collection.add({ name: `test${i}` }))
		collection.delete(first, 0)
	})

	it('should return non deleted items', () => {
		const activeItems = collection.active

		expect(activeItems).toHaveLength(2)
		expect(activeItems).toContain(second, third)
	})
})

describe('deleted', () => {
	set('collection', () => new Collection)
	set('first', () => collection.first)
	set('second', () => collection[1])
	set('third', () => collection.last)

	beforeEach(() => {
		range(1, 4).forEach(i => collection.add({ name: `test${i}` }))
		collection.delete(first, 0)
	})

	it('should return non deleted items', () => {
		const activeItems = collection.deleted

		expect(activeItems).toHaveLength(1)
		expect(activeItems).toContain(first)
	})
})
