import Alpine from 'alpinejs'
import { filter, reject } from 'lodash'
import Macro from '../../src/macro_lists/Macro'

// Use Proxy to extend array setter and ensure that some macro's attributes are always in sync
const macros = new Proxy([], {
	set(obj, prop, value) {
		if (value.constructor === Macro) {
			value.position = parseInt(prop) + 1 // Setting macro's position based on index
			value.isFirst = value.position === 1
			value.isLast = !value.isDeleted && (!obj[prop + 1] || obj[prop + 1].isDeleted)
		}

		obj[prop] = value

		return true
	}
})

Alpine.store('macroList', {
	selectedType: '',
	macros,
	isShow: false,
	activeMacros() { return reject(this.macros, 'isDeleted') },
	deletedMacros() { return filter(this.macros, 'isDeleted') },
	addMacro(attributes) {
		this.macros.push(new Macro(attributes))
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
