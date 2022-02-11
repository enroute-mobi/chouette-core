import Alpine from 'alpinejs'

import { filter, reject } from 'lodash'

import Macro from '../../src/macro_lists/Macro'

Alpine.store('macroList', {
	selectedType: '',
	macros: [],
	isShow: false,
	activeMacros() { return reject(this.macros, 'isDeleted') },
	deletedMacros() { return filter(this.macros, 'isDeleted') },
	addMacro(attributes) {		
		this.macros.push(new Macro({ ...attributes, store: this } ))
	},
	setMacros(macros) {
		macros.forEach(m => this.addMacro(m))
	},
	duplicate(macro) {
		this.addMacro(Macro.from(macro))
	},
	moveUp(index) {
		this.swapMacros(index, index - 1)
	},
	moveDown(index) {
		this.swapMacros(index, index + 1)
	},
	sendToTop(index) {
		do {
			this.moveUp(index)

			index -= 1
		} while (index > 0)
	},
	sendToBottom(index) {
		do {
			this.moveDown(index)

			index += 1
		} while (index < this.macros.length - 1)
	},
	delete(macro, index) {
		this.sendToBottom(index)
		macro.delete()
	},
	restore(macro) {
		macro.restore()

		this.macros = [
			...reject(this.activeMacros(), ['uuid', macro.uuid]),
			macro,
			...this.deletedMacros()
		]
	},
	swapMacros(indexA, indexB) {
		if (!!this.macros[indexA] && !!this.macros[indexB]) {
			[this.macros[indexA], this.macros[indexB]] = [this.macros[indexB], this.macros[indexA]]
		}
	}
})
