import Select from './base.select'

const isEdit = location.pathname.includes('edit')

export default class ProcessableIdSelect extends Select {
	constructor(selectId, form) {
		super(selectId, form)

		// Ensure that select value is set on edit form
		this.tomSelect.on('load', () => {
			const { processableId } = this.form
			const selectedItem = this.tomSelect.getItem(this.form.processableId)

			if (!!processableId && !selectedItem) {
				this.tomSelect.addItem(processableId, true)
			}
		})
	}

	shouldLoad(_query) {
		return this.form.hasProcessableType()
	}

	async load(query, callback) {
		const { baseURL, processableId, processableType, workgroupRule } = this.form
		const searchParams = new URLSearchParams()

		searchParams.set('search[query]', encodeURIComponent(query))
		searchParams.set('search[processable_type]', processableType)
		searchParams.set('search[workgroup_rule]', workgroupRule)

		const url = `${baseURL}/get_processables?${searchParams}`

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
			type: 'ajax',
			preload: isEdit,
			shouldLoad: this.shouldLoad.bind(this),
			load: this.load.bind(this)
		}
	}
}
