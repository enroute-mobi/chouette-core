import { ControlContext, ControlContextCollection } from '../../../app/packs/src/control_lists/controlContext'

context('ControlContext', () => {
	set('controlContext', () => new ControlContext({}))

	describe('inputSelector', () => {
		it('should return control_contexts_attributes', () => {
			expect(controlContext.inputSelector).toEqual('control_contexts_attributes')
		})
	})

	describe('attributesList', () => {
		it('should return the right list', () => {
			expect(controlContext.attributesList).toEqual(['nodeId', 'errors', 'html', 'controls'])
		})
	})
})

context('ControlContextCollection', () => {
	describe('ResourceConstructor', () => {
		it('should return ControlContext', () => {
			expect(ControlContextCollection.ResourceConstructor).toEqual(ControlContext)
		})
	})

	describe('duplicate', () => {
		set('collection', () => new ControlContextCollection)
		set('controlContext', () => collection.first)

		beforeEach(() => {
			collection.add({ id: 1, name: 'context1'})
			controlContext.controls.add({ id: 1, name: 'test' })
		})
	
		it('should duplicate an controlContext & its controls', async () => {
			await collection.duplicate(controlContext)

			expect(collection).toHaveLength(2)

			expect(collection.last.controls).toHaveLength(1)
		})

		it('should remove id from duplicates', async () => {
			await collection.duplicate(controlContext)

			const duplicate = collection.last
			expect(duplicate.id).toBeUndefined()

			expect(duplicate.controls.first.id).toBeUndefined()
		})
	})
})
