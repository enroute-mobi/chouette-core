import { Path } from 'path-parser'

const paths = Array.of(
	'/workbenches/:id/macro_lists',
	'/workbenches/:workbenchId/macro_lists/fetch_macro_html'
).map(Path.createPath)

const workbenchId = paths[0].partialTest(location.pathname)?.id
export default class HTMLFinder {
	constructor(attributes) {
		for (const key in attributes) {
			this[key] = attributes[key]
		}

		if (!this.macro.hasErrors && !!this.macro.html) {
			this.cacheHTML = this.macro.html
		}
	}

	async render() {
		return this.updateHTML(this.macro.html || this.cacheHTML || await this.fecthedHTML())
	}

	get cacheHTML() { return sessionStorage.getItem(this.macro.type) }

	set cacheHTML(html) {
		sessionStorage.setItem(this.macro.type, html)
	}

	async fecthedHTML() {
		const params = new URLSearchParams()
		params.set('html[id]', this.macro.id)
		params.set('html[type]', this.macro.type)

		const url = paths[1].build({ workbenchId }) + '.json?' + params.toString()

		const { html } = await (await fetch(url)).json()

		this.cacheHTML = html

		return html
	}

	// Based on given index update every macro inputs (id & name)
	// This is to avoid conflicts between sub forms
	updateHTML(html) {
		const doc = new DOMParser().parseFromString(html, 'text/html')

		doc.querySelectorAll(`[name*=macros_attributes]`).forEach(i => {
			i.name = i.name.replace(/\[\d+\]/, `[${this.index}]`)
			i.id = i.id.replace(/_\d+_/, `_${this.index}_`)
		})

		return doc.body.innerHTML
	}
}
