import Alpine from 'alpinejs'
import { Path } from 'path-parser'
import { filter, findIndex, omit, reject } from 'lodash'

const parser = new DOMParser()

/**
 * Check the session storage for a cache HTML string related to the macroType
 * @param {macroType} string The type of the macro
 * @return {Promise}
 */
const checkHTMLCache = macroType => {
	return new Promise((resolve, reject) => {
		const html = sessionStorage.getItem(macroType)

		Boolean(!!html) ? resolve(html) : reject()
	})
}

// Based on given index update every macro inputs (id & name)
// This is to avoid conflicts between sub forms
const updateInputNames = index => html => {
	const doc = parser.parseFromString(html, 'text/html')

	doc.querySelectorAll(`[name*=macros_attributes]`).forEach(i => {
		i.name = i.name.replace(/\[\d+\]/, `[${index}]`)
		i.id = i.id.replace(/_\d+_/, `_${index}_`)
	})

	return doc.body.innerHTML
}

const getURLParams = () => 
	Array
		.of(
			'/workbenches/:id/macro_lists',
			'/workbenches/:workbenchId/macro_lists/:id<d+>'
		)
		.map(p => Path.createPath(p).partialTest(location.pathname)?.id || {})

const [workbenchId, id] = getURLParams()
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

/**
 * Based on macro index (in macros list) return the HTML related to macro sub form
 * Either by getting the cached one or fetching it from the server
 * @param {index} integer The index of the macro in the macros list
 * @return {Promise{html}} a promise which result is a HTML string
 */
	getHTML(index) {
		const inputUpdater = updateInputNames(index)

		return checkHTMLCache(this.type)
			.then(inputUpdater)
			.catch(async () => {
				const params = new URLSearchParams({ type: this.type })

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

				return inputUpdater(html)
			})
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
