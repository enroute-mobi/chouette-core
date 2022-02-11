import { bindAll } from 'lodash'
import { Path } from 'path-parser'

const parser = new DOMParser()

const getURLParams = () =>
	Array
		.of(
			'/workbenches/:id/macro_lists',
			'/workbenches/:workbenchId/macro_lists/:id<d+>'
		)
		.map(p => Path.createPath(p).partialTest(location.pathname)?.id || {})

const [workbenchId, id] = getURLParams()

export default class HTMLFinder {
	constructor(macroId, macroType, index) {
		this.macroId = macroId
		this.macroType = macroType
		this.index = index

		bindAll(this, ['fecthHTML', 'updateInputNames'])
	}

	render() {
		return this.checkHTMLCache()
			.catch(this.fecthHTML)
			.then(this.updateInputNames)
	}

	/**
 * Check the session storage for a cache HTML string related to the macroType
 * @param {macroType} string The type of the macro
 * @return {Promise}
 */
	checkHTMLCache() {
		return new Promise((resolve, reject) => {
			const html = sessionStorage.getItem(this.macroType)

			Boolean(!!html) ? resolve(html) : reject()
		})
	}

	async fecthHTML() {
		const params = new URLSearchParams({ type: this.macroType })

		this.macroId && params.set('id', this.macroId)
		Boolean(parseInt(id)) && params.set('macro_list_id', id)

		const url = Path
			.createPath('/workbenches/:workbenchId/macro_lists/fetch_macro_html')
			.build({ workbenchId }) +
			'.json?' +
			params.toString()

		const response = await fetch(url)
		const { html } = await response.json()

		sessionStorage.setItem(this.macroType, html) // Caching result

		return html
	}

	// Based on given index update every macro inputs (id & name)
	// This is to avoid conflicts between sub forms
	updateInputNames(html) {
		const doc = parser.parseFromString(html, 'text/html')

		doc.querySelectorAll(`[name*=macros_attributes]`).forEach(i => {
			i.name = i.name.replace(/\[\d+\]/, `[${this.index}]`)
			i.id = i.id.replace(/_\d+_/, `_${this.index}_`)
		})

		return doc.body.innerHTML
	}
}
