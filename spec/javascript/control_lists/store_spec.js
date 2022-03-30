import Store from '../../../app/packs/src/control_lists/store'
import { Control } from '../../../app/packs/src/control_lists/control'
import { ControlContext } from '../../../app/packs/src/control_lists/controlContext'

const intitialState = {
	name: 'foo',
	comments: 'bar',
	controls: [{ id: 1, name: 'control1' }, { name: 'control2', criticity: 'error' }],
	control_contexts: [
		{ id: 1, name: 'context1', controls: [{ id: 2, name: 'control3' }] },
		{ id: 2, name: 'context2' }
	]
}
describe('initState', () => {
	set('store', () => new Store)

	beforeEach(() => store.initState(intitialState))

	it('should update the store', () => {
		const { name, comments, controls, contexts } = store
	
		expect(name).toEqual('foo')
		expect(comments).toEqual('bar')

		expect(controls).toHaveLength(2)
		expect(controls.first.constructor).toEqual(Control)

		expect(contexts).toHaveLength(2)
		expect(contexts.first.constructor).toEqual(ControlContext)

		expect(contexts.first.controls.first.constructor).toEqual(Control)
	})
})

describe('setFormData', () => {
	set('store', () => new Store)
	set('formData', () => new FormData())

	beforeEach(() => store.initState(intitialState))

	it('should update the formData Object', () => {
		store.contexts[1].delete()
		store.setFormData({ formData })

		const result = new Map([...formData])
		const keys = [...result.keys()]

		expect(result.get('control_list[name]')).toEqual('foo')
		expect(result.get('control_list[comments]')).toEqual('bar')

		// Controls
		const controlKeys = keys.filter(k => /^control_list\[controls_attributes\]/.test(k))

		expect(controlKeys).toHaveLength(9)
	
		expect(result.get('control_list[controls_attributes][0][id]')).toEqual('1')
		expect(result.get('control_list[controls_attributes][0][name]')).toEqual('control1')
		expect(result.get('control_list[controls_attributes][0][criticity]')).toEqual('warning')
		expect(result.get('control_list[controls_attributes][0][position]')).toEqual('1')
		expect(result.get('control_list[controls_attributes][0][_destroy]')).toEqual('false')
	
		expect(result.has('control_list[controls_attributes][1][id]')).toBeFalsy()
		expect(result.get('control_list[controls_attributes][1][name]')).toEqual('control2')
		expect(result.get('control_list[controls_attributes][1][criticity]')).toEqual('error')
		expect(result.get('control_list[controls_attributes][1][position]')).toEqual('2')
		expect(result.get('control_list[controls_attributes][1][_destroy]')).toEqual('false')

		// Control Contexts
		const controlContextKeys = keys.filter(k => /^control_list\[control_contexts_attributes\]\[\d+\]\[\w+\]$/.test(k))

		expect(controlContextKeys).toHaveLength(4 * 2)
		
		expect(result.get('control_list[control_contexts_attributes][0][id]')).toEqual('1')
		expect(result.get('control_list[control_contexts_attributes][0][name]')).toEqual('context1')
		expect(result.get('control_list[control_contexts_attributes][0][position]')).toEqual('1')
		expect(result.get('control_list[control_contexts_attributes][0][_destroy]')).toEqual('false')
		expect(result.get('control_list[control_contexts_attributes][0][controls_attributes][0][id]')).toEqual('2')
		expect(result.get('control_list[control_contexts_attributes][0][controls_attributes][0][name]')).toEqual('control3')
		expect(result.get('control_list[control_contexts_attributes][0][controls_attributes][0][criticity]')).toEqual('warning')
		expect(result.get('control_list[control_contexts_attributes][0][controls_attributes][0][position]')).toEqual('1')
		expect(result.get('control_list[control_contexts_attributes][0][controls_attributes][0][_destroy]')).toEqual('false')
	
		expect(result.get('control_list[control_contexts_attributes][1][id]')).toEqual('2')
		expect(result.get('control_list[control_contexts_attributes][1][name]')).toEqual('context2')
		expect(result.get('control_list[control_contexts_attributes][1][position]')).toEqual('2')
		expect(result.get('control_list[control_contexts_attributes][1][_destroy]')).toEqual('true')


	})
})
