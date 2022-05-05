import { omit } from 'lodash'
import { Path } from 'path-parser'
import { isProd } from '../../../src/helpers/env'

const path = Path.createPath('/workbenches/:workbenchId/:controllerName')
const URLParams = path.partialTest(location.pathname)

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

	get attributesList() { return ['nodeId', 'errors', 'html'] }
	
	get cacheHTML() { return sessionStorage.getItem(this.type) }

	set cacheHTML(html) { sessionStorage.setItem(this.type, html) }

	async fecthedHTML() {
		const searchParams = new URLSearchParams()
		searchParams.set('html[type]', this.type)

		const url = path.build(URLParams) + '/fetch_object_html.json?' + searchParams.toString()

		const { html } = await (await fetch(url)).json()

		if (isProd) {
			this.cacheHTML = html
		}

		return html
	}
}
