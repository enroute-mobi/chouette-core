import { Control, ControlCollection } from '../../../app/packs/src/control_lists/control'

context('Control', () => {
	describe('inputSelector', () => {
		set('control', () => new Control)

		it('should return controls_attributes', () => {
			expect(control.inputSelector).toEqual('controls_attributes')
		})
	})
})

context('ControlCollection', () => {
	describe('ResourceConstructor', () => {
		it('should return Control', () => {
			expect(ControlCollection.ResourceConstructor).toEqual(Control)
		})
	})
})
