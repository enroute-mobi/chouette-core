import Alpine from 'alpinejs'
import { Path } from 'path-parser'

const { workbenchId, id } = Path
	.createPath('/workbenches/:workbenchId/macro_lists/:id')
	.partialTest(location.pathname)

import { filter, findIndex, omit, reject } from 'lodash'
class Macro {
	constructor(attributes) {
		this.uuid = crypto.randomUUID()
		this.isDeleted = false

		for (const key in attributes) {
			this[key] = attributes[key]
		}
	}

	static from(macro) {
		const attributes = omit(Object.assign(macro), ['id', 'uuid', 'isDeleted'])
		return new Macro(attributes)
	}

	get position() {
		return findIndex(this.store.macros, ['uuid', this.uuid]) + 1
	}

	isFirst() {
		return this.position === 1
	}

	isLast() {
		return this.position == this.store.activeMacros().length
	}

	delete() {
		this.isDeleted = true
	}

	restore() {
		this.isDeleted = false
	}

	async getHTML(index) {
		const cachedHTML = sessionStorage.getItem(this.type)

		if (!!cachedHTML) return cachedHTML

		const params = new URLSearchParams({ type: this.type, index })

		this.id && params.set('id', this.id)
		Boolean(parseInt(id)) && params.set('macro_list_id', id)

		const url = Path
			.createPath('/workbenches/:workbenchId/macro_lists/fetch_macro_html')
			.build({ workbenchId }) +
			'.json?' +
			params.toString()

		const response = await fetch(url)
		const { html } = await response.json()

		sessionStorage.setItem(this.type, html) // Caching result

		return html
	}
}

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
