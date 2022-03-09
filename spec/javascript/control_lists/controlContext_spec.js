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
			expect(controlContext.attributesList).toEqual(['errors', 'html', 'controls'])
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
			collection.add({ name: 'context1'})
			controlContext.controls.add({ name: 'test' })
		})
	
		it('should duplicate an controlContext & its controls', async () => {
			await collection.duplicate(controlContext)

			expect(collection).toHaveLength(2)

			expect(collection.last.controls).toHaveLength(1)
		})
	})
})
