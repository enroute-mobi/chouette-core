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
		return this.object.html || this.cacheHTML || await this.fecthedHTML()
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
}
