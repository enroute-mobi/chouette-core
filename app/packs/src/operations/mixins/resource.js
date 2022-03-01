import { omit } from 'lodash'
import { Path } from 'path-parser'

const path = Path.createPath('/workbenches/:workbenchId/macro_lists')
const workbenchId = path.partialTest(location.pathname)?.workbenchId

export default superclass => class Resource extends superclass {
	constructor(attributes) {
		super(attributes)

		this._destroy = false
		this.errors = []

		for (const key in attributes) {
			this[key] = attributes[key]
		}		
	}

	get isDeleted() { return this._destroy }

	get hasErrors() { return this.errors.length > 0 }

	get attributes() { return omit(this, this.attributesList) }

	delete() { this._destroy = true }

	restore() { this._destroy = false }

	async render() { return this.html || this.cacheHTML || await this.fecthedHTML() }

	get attributesList() { return ['errors', 'html'] }
	
	get cacheHTML() { return sessionStorage.getItem(this.type) }

	set cacheHTML(html) { sessionStorage.setItem(this.type, html) }

	async fecthedHTML() {
		const params = new URLSearchParams()
		params.set('html[id]', this.id)
		params.set('html[type]', this.type)

		const url = path.build({ workbenchId }) + '/fetch_object_html.json?' + params.toString()

		const { html } = await (await fetch(url)).json()

		this.cacheHTML = html

		return html
	}
}
