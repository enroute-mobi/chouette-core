import Store from '../../../app/packs/src/operations/macro.store'
import { Macro } from '../../../app/packs/src/operations/macro'
import { MacroContext } from '../../../app/packs/src/operations/macroContext'

const intitialState = {
	name: 'foo',
	comments: 'bar',
	macros: [{ id: 1, name: 'macro1' }, { name: 'macro2' }],
	macro_contexts: [
		{ id: 1, name: 'context1', macros: [{ id: 2, name: 'macro3' }] },
		{ id: 2, name: 'context2' }
	]
}
describe('initState', () => {
	set('store', () => new Store)

	beforeEach(() => store.initState(intitialState))

	it('should update the store', () => {
		const { name, comments, macros, contexts } = store
	
		expect(name).toEqual('foo')
		expect(comments).toEqual('bar')

		expect(macros).toHaveLength(2)
		expect(macros.first.constructor).toEqual(Macro)

		expect(contexts).toHaveLength(2)
		expect(contexts.first.constructor).toEqual(MacroContext)

		expect(contexts.first.macros.first.constructor).toEqual(Macro)
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

		expect(result.get('macro_list[name]')).toEqual('foo')
		expect(result.get('macro_list[comments]')).toEqual('bar')

		// Macros
		const macroKeys = keys.filter(k => /^macro_list\[macros_attributes\]/.test(k))

		expect(macroKeys).toHaveLength(4 * 2)
	
		expect(result.get('macro_list[macros_attributes][0][id]')).toEqual('1')
		expect(result.get('macro_list[macros_attributes][0][name]')).toEqual('macro1')
		expect(result.get('macro_list[macros_attributes][0][position]')).toEqual('1')
		expect(result.get('macro_list[macros_attributes][0][_destroy]')).toEqual('false')
	
		expect(result.get('macro_list[macros_attributes][1][id]')).toEqual('')
		expect(result.get('macro_list[macros_attributes][1][name]')).toEqual('macro2')
		expect(result.get('macro_list[macros_attributes][1][position]')).toEqual('2')
		expect(result.get('macro_list[macros_attributes][1][_destroy]')).toEqual('false')

		// Macro Contexts
		const macroContextKeys = keys.filter(k => /^macro_list\[macro_contexts_attributes\]\[\d+\]/.test(k))

		expect(macroContextKeys).toHaveLength(4 * 2)
		
		expect(result.get('macro_list[macro_contexts_attributes][0][id]')).toEqual('1')
		expect(result.get('macro_list[macro_contexts_attributes][0][name]')).toEqual('context1')
		expect(result.get('macro_list[macro_contexts_attributes][0][position]')).toEqual('1')
		expect(result.get('macro_list[macro_contexts_attributes][0][_destroy]')).toEqual('false')
		expect(result.get('macro_list[macro_contexts_attributes][0][macros_attributes][0][id]')).toEqual('2')
		expect(result.get('macro_list[macro_contexts_attributes][0][macros_attributes][0][name]')).toEqual('macro3')
		expect(result.get('macro_list[macro_contexts_attributes][0][macros_attributes][0][position]')).toEqual('1')
		expect(result.get('macro_list[macro_contexts_attributes][0][macros_attributes][0][_destroy]')).toEqual('false')
	
		expect(result.get('macro_list[macro_contexts_attributes][1][id]')).toEqual('2')
		expect(result.get('macro_list[macro_contexts_attributes][1][name]')).toEqual('context2')
		expect(result.get('macro_list[macro_contexts_attributes][1][position]')).toEqual('2')
		expect(result.get('macro_list[macro_contexts_attributes][1][_destroy]')).toEqual('true')


	})
})
