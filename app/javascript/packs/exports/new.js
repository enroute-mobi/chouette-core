import TomSelect from 'tom-select'
class SelectBuilder {
	static init(selector, pathBuilder, initialValue = []) {
		new TomSelect(selector, {
			preload: true,
			openOnFocus: true,
			load: (query, callback) => (
				fetch(`${pathBuilder()}?q=${encodeURIComponent(query)}`)
					.then(res => res.json().then(callback))
					.catch(() => callback())
			),
			valueField: 'id',
			labelField: 'text',
			items: initialValue.map(item => item.id),
			options: initialValue
		})
	}
}
class PathBuilder {
	constructor(store) {
		this.store = store

		this.workbenchId = window.location.pathname.match(/(\d+)/)[0]
		this.workgroupId = window.location.pathname.match(/\d+/)[0]
	}

	get lineIds() {
		return () => 
			this.store.isExport ?
				`/referentials/${this.store.referentialId}/autocomplete/lines` :
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
		SelectBuilder.init(`#${this.baseName}_line_ids`, this.pathBuilder.lineIds, lineIds)
	},
	initCompanyIdsSelect(companyIds) {
		SelectBuilder.init(`#${this.baseName}_company_ids`, this.pathBuilder.companyIds, companyIds)
	},
	initLineProviderIdsSelect(lineProviderIds) {
		SelectBuilder.init(`#${this.baseName}_line_provider_ids`, this.pathBuilder.lineProviderIds, lineProviderIds)
	},
	initLineCodeSelect() {
		SelectBuilder.init(`#${this.baseName}_line_code`, this.pathBuilder.lineIds)
	}
})

window.Spruce.watch('export.isExport', isExport => {
	!isExport && window.Spruce.stores.export.setState({ exportType: 'full' })
	window.Spruce.stores.export.setState({
		baseName: isExport ? 'export_options' : 'publication_setup_export_options' })
})
