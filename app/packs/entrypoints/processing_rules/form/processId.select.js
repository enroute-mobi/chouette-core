import { Path } from 'path-parser'
import Select from './base.select'

const isEdit = location.pathname.includes('edit')

export default class ProcessableIdSelect extends Select {
	constructor(form, xRef, baseURL) {
		super(form, xRef)

		this.baseURL = baseURL
	}

	get path() { return new Path(this.baseURL) }


	shouldLoad(_query) {
		return this.form.hasProcessableType()
	}

	async load(query, callback) {
		const searchParams = new URLSearchParams()

		searchParams.set('search[query]', encodeURIComponent(query))
		searchParams.set('search[processable_type]', this.form.processableType)

		const url = `${this.baseURL}/get_processables?${searchParams}`

		try {
			const { processables } = await (await fetch(url)).json() 
			callback(processables)
		} catch (e) {
			callback()
		}
	}

	reload() {
		super.reload()
		this.tomSelect.load('')
	}

	get params() {
		return {
			preload: isEdit,
			shouldLoad: this.shouldLoad.bind(this),
			load: this.load.bind(this)
		}
	}
}
