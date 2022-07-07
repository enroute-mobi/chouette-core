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

	load(query, callback) {
		const searchParams = new URLSearchParams()

		searchParams.set('search[query]', encodeURIComponent(query))
		searchParams.set('search[processable_type]', this.form.processableType)

		const url = `${this.baseURL}/get_processables?${searchParams}`

		fetch(url)
			.then(res => res.json())
			.then(json => {
				callback(json.processables)()
			})
			.catch(() => { })
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

	get label() {
		const { processableType } = this.form

		switch (processableType) {
			case '':
			case null:
			case undefined:
				return I18n.t('activerecord.attributes.processing_rule.processable_id')
			case 'Macro::List':
			case 'Control::List':
				const key = processableType.replace('::', '/').toLowerCase()

				return I18n.t(`activerecord.models.${key}.one`)
		}
	}
}
