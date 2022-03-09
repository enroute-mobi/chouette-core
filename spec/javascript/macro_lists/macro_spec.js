import { Macro, MacroCollection } from '../../../app/packs/src/macro_lists/macro'

context('Macro', () => {
	describe('inputSelector', () => {
		set('macro', () => new Macro)

		it('should return macros_attributes', () => {
			expect(macro.inputSelector).toEqual('macros_attributes')
		})
	})
})

context('MacroCollection', () => {
	describe('ResourceConstructor', () => {
		it('should return Macro', () => {
			expect(MacroCollection.ResourceConstructor).toEqual(Macro)
		})
	})
})
