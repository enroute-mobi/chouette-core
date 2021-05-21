import TomSelect from 'tom-select'
class SelectBuilder {
	static init(selector, pathBuilder, initialValue = []) {
		new TomSelect(selector, {
			preload: 'focus',
			openOnFocus: true,
			load: async (query, callback) => {
				const path = `${pathBuilder()}?q=${encodeURIComponent(query)}`

				try {
					const response = await fetch(path)
					await response.json().then(callback)
				} catch(error) {
					callback()
				}
			},
			valueField: 'id',
			labelField: 'text',
			options: initialValue,
			items: initialValue.map(item => item.id)
		})
	}
}
class PathBuilder {
	constructor(store) {
		this.store = store

		if (!this.store.isExport) {
			this.workbenchId = window.location.pathname.match(/(\d+)/)[0]
			this.workgroupId = window.location.pathname.match(/\d+/)[0]
		}
	}

	get lineIds() {
		return () => 
			this.store.isExport ?
				`/referentials/${this.this.referentialId}/autocomplete/lines` :
				`/workgroups/${this.workgroupId}/autocomplete/lines`
	}

	get companyIds() {
		return () => store.isExport ?
			`/referentials/${this.store.referentialId}/autocomplete/companies` :
			`/workgroups/${this.workgroupId}/autocomplete/companies`

	}

	get lineProviderIds() {
		return () => store.isExport ?
			`/workbenches/${this.workbenchId}/autocomplete/line_providers` :
			`/workgroups/${this.workgroupId}/autocomplete/line_providers`
	}
}

window.Spruce.store('export', {
	type: 'Export::Gtfs',
	exportedLines: 'all_line_ids',
	referentialId: '',
	isExport: null,
	pathBuilder: new PathBuilder(this),
	setState(newState) {
		Object.entries(newState).forEach(([key, value]) => {
			this[key] = value
		})
	},
	initReferentialIdSelect() {
		new TomSelect('#export_referential_id', {}).on('change', value => this.referentialId = value)
	},
	initLineIdsSelect(lineIds) {
		// this.setState({ lineIds })
		SelectBuilder.init('#export_line_ids', this.pathBuilder.lineIds, lineIds)
	},
	initCompanyIdsSelect(companyIds) {
		// this.setState({ companyIds })
		SelectBuilder.init('#export_company_ids', this.pathBuilder.companyIds, companyIds)
	},
	initLineProviderIdsSelect(lineProviderIds) {
		// this.setState({ lineProviderIds })
		SelectBuilder.init('#export_line_provider_ids', this.pathBuilder.lineProviderIds, lineProviderIds)
	}
})

window.Spruce.watch('export.isExport', isExport => {
	!isExport && window.Spruce.stores.export.setState({ exportType: 'full' })
})
