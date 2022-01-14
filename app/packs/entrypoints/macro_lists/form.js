import Alpine from 'alpinejs'

import { add, filter, findIndex, flow, omit, partialRight, reduce, uniqueId } from 'lodash'

Alpine.store('macroList', {
	selectedType: '',
	macros: [],
	actions: ['duplicate', 'send_to_top', 'move_up', 'move_down', 'send_to_bottom', 'delete', 'restore'],
	addMacro(attributes) {
		this.macros = [...this.macros, { ...attributes, isDeleted: false, uniqueId: uniqueId('macro_') }]
	},
	setMacros(macros) {
		macros.forEach(this.addMacro.bind(this))
	},
	getMacro(index) {
		return this.macros[index]
	},
	getPosition(macro) {
		if (macro.isDeleted) return null

		const filterNotDeletedMacros = partialRight(filter, m => !m.isDeleted) // We need to determine macro position from non-deleted macros and not the whole collection
		const findMacroIndex = partialRight(findIndex, ['uniqueId', macro.uniqueId])
		const addOneToIndex = partialRight(add, 1) // Adding one to index to get a position
		
		return flow(filterNotDeletedMacros, findMacroIndex, addOneToIndex)(this.macros)
	},
	duplicate(index) {
		this.addMacro(
			omit(this.getMacro(index), ['id', 'uniqueId', 'created_at', 'updated_at']),
		)
	},
	move_up(index) {
		if (index == 0) return

		this.swapMacro(index, index - 1)
	},
	move_down(index) {
		if (index + 1 == this.macros.length) return

		this.swapMacro(index, index + 1)
	},
	send_to_top(index) {
		this.macros = [
			this.getMacro(index),
			...this.macros.filter((_m, i) => i != index),
		]
	},
	send_to_bottom(index) {
		this.macros = [
			...this.macros.filter((_m, i) => i != index),
			this.getMacro(index)
		]
	},
	delete(index) {
		this.macros = reduce(this.macros, (result, macro, macroIndex) => [
			...result,
			{
				...macro,
				...index == macroIndex ? { isDeleted: true } : {}
			}
		], [])
	},
	restore(index) {
		this.macros = reduce(this.macros, (result, macro, macroIndex) => [
			...result,
			{
				...macro,
				...index == macroIndex ? { isDeleted: false } : {}
			}
		], [])
	},
	swapMacro(indexA, indexB) {
		[this.macros[indexA], this.macros[indexB]] = [this.macros[indexB], this.macros[indexA]]
	},
	inputName(index, name) { return `macro_list[macros_attributes][${index}][${name}]` },
})

