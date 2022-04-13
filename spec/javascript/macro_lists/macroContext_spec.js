import { MacroContext, MacroContextCollection } from '../../../app/packs/src/macro_lists/macroContext'

context('MacroContext', () => {
	set('macroContext', () => new MacroContext({}))

	describe('inputSelector', () => {
		it('should return macro_contexts_attributes', () => {
			expect(macroContext.inputSelector).toEqual('macro_contexts_attributes')
		})
	})

	describe('attributesList', () => {
		it('should return the right list', () => {
			expect(macroContext.attributesList).toEqual(['nodeId', 'errors', 'html', 'macros'])
		})
	})
})

context('MacroContextCollection', () => {
	describe('ResourceConstructor', () => {
		it('should return MacroContext', () => {
			expect(MacroContextCollection.ResourceConstructor).toEqual(MacroContext)
		})
	})

	describe('duplicate', () => {
		set('collection', () => new MacroContextCollection)
		set('macroContext', () => collection.first)

		beforeEach(() => {
			collection.add({ id: 1, name: 'context1'})
			macroContext.macros.add({ id: 1, name: 'test' })
		})
	
		it('should duplicate an macroContext & its macros', async () => {
			await collection.duplicate(macroContext)

			expect(collection).toHaveLength(2)

			expect(collection.last.macros).toHaveLength(1)
		})

		it('should remove id from duplicates', async () => {
			await collection.duplicate(macroContext)

			const duplicate = collection.last
			expect(duplicate.id).toBeUndefined()

			expect(duplicate.macros.first.id).toBeUndefined()
		})
	})
})
