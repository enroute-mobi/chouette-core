import { Path } from 'path-parser'

const path = Path.createPath('/workbenches/:workbenchId/macro_lists')

const workbenchId = path.partialTest(location.pathname)?.workbenchId
export default class HTMLFinder {
	constructor(attributes) {
		for (const key in attributes) {
			this[key] = attributes[key]
		}

		if (!this.object.hasErrors && !!this.object.html) {
			this.cacheHTML = this.object.html
		}
	}

	async render() {
		return this.updateHTML(this.object.html || this.cacheHTML || await this.fecthedHTML())
	}

	get cacheHTML() { return sessionStorage.getItem(this.object.type) }

	set cacheHTML(html) {
		sessionStorage.setItem(this.object.type, html)
	}

	async fecthedHTML() {
		const params = new URLSearchParams()
		params.set('html[id]', this.object.id)
		params.set('html[type]', this.object.type)

		const url = path.build({ workbenchId }) + '/fetch_object_html.json?' + params.toString()

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
