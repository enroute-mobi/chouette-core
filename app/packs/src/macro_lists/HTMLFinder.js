import { Path } from 'path-parser'

const path = Path.createPath('/workbenches/:workbenchId/macro_lists')

const workbenchId = path.partialTest(location.pathname)?.workbenchId
export default class HTMLFinder {
	constructor(index, object) {
		this.index = index
		this.object = object

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

		const input = this.object.input

		const nameRegex = new RegExp(`\\[${input.selector}\\]\\[[0-9]+\\]`)
		const idRegex = new RegExp(`${input.selector}_[0-9]+`)

		doc.querySelectorAll(`[name*=${input.selector}]`).forEach(i => {
			i.name = i.name.replace(nameRegex, input.replaceName)
			i.id = i.id.replace(idRegex, input.replaceId)
		})

		return doc.body.innerHTML
	}
}
